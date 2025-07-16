import argparse
import os
import pathlib
import torch
import torch.nn as nn
import torch.optim as optim
import random
from collrections import deque, namedtuple

# godot環境とのブリッジ用ラッパー
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baseline3.common.vec_env.vec_monitor import VecMonitor

Transition = namedtuple('Transition', ('state', 'action', 'reward', 'next_state', 'done', 'logprob'))

class ReplayBuffer:
    def __init__(self, capacity):
        self.buffer = deque(maxlen=capacity)

    def push(self, *args):
        self.buffer.append(Transition(*args))

    def sample(self, batch_size):
        return random.sample(self.buffer, batch_size)

    def __len__(self):
        return len(self.buffer)
    
class PolicyNet(nn.Module):
    """
    ポリシー＆バリューネットワーク
    入力: 観測ベクトル (obs_dim)
    出力: アクションのlogits (離散) と状態価値V(s)
    """
    def __init__(self, obs_dim, action_dim, hidden_sizes=[64, 64]):
        super().__init__()
        # 中間層の構築
        layers = []
        last_size = obs_dim
        for h in hidden_sizes:
            layers += [nn.Linear(last_size, h), nn.ReLU()]
            last_size = h
        self.backbone = nn.Sequential(*layers)
        # ポリシーヘッド（離散アクション用ロジット）
        self.policy_head = nn.Linear(last_size, action_dim)
        # バリューヘッド（状態価値V(s)）
        self.value_head  = nn.Linear(last_size, 1)

    def forward(self, x):
        """
        フォワードパス
        :param x: 状態ベクトル (batch x obs_dim)
        :return: (logits, value)
        """
        h = self.backbone(x)
        return self.policy_head(h), self.value_head(h).squeeze(-1)

def parse_args():
    """ コマンドライン引数の定義とパース """
    parser = argparse.ArgumentParser(description="Godot環境で自作RLアルゴリズムを学習")
    # Godot実行ファイルのパス
    parser.add_argument("--env_path", default=None, type=str,
                        help="Godotバイナリへのパス（未指定時はエディタ内トレーニング）")
    # ログ／チェックポイント保存先
    parser.add_argument("--experiment_dir", default="logs/rl", type=str,
                        help="実験ディレクトリ（TensorBoardログやモデル保存先）")
    parser.add_argument("--experiment_name", default="experiment", type=str,
                        help="実験名（ディレクトリ名／TensorBoard上で表示）")
    # シード値／並列数／速度調整
    parser.add_argument("--seed", type=int, default=0, help="乱数シード")
    parser.add_argument("--n_parallel", type=int, default=1,
                        help="並列環境数（>1の場合はenv_path必須）")
    parser.add_argument("--speedup", type=int, default=1,
                        help="物理演算のスピードアップ倍率")
    # グラフィック表示の有無
    parser.add_argument("--viz", action="store_true", default=False,
                        help="トレーニング時にウィンドウを表示")
    # トレーニング／推論モード切替
    parser.add_argument("--inference", action="store_true", default=False,
                        help="推論モードで動作 (学習は行わない)")
    # 再開用モデルパス
    parser.add_argument("--resume_model_path", type=str, default=None,
                        help="学習再開または推論用のモデルファイルパス (.pt)")
    # 最大エピソード数
    parser.add_argument("--max_episodes", type=int, default=1000,
                        help="トレーニングエピソード数の上限")
    args = parser.parse_args()

    # 推論時にはモデルパス必須
    if args.inference and args.resume_model_path is None:
        parser.error("--inference を使う場合は --resume_model_path を指定してください。")
    return args


def main():
    # 引数パース
    args = parse_args()

    # デバイス設定 (GPUがあれば利用)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Godot環境の初期化
    env = StableBaselinesGodotEnv(
        env_path=args.env_path,
        show_window=args.viz,
        seed=args.seed,
        n_parallel=args.n_parallel,
        speedup=args.speedup
    )
    # VecMonitorでエピソード長や報酬を自動集計
    env = VecMonitor(env)

    # 観測次元・行動次元を取得
    obs_dim = env.observation_space.shape[0]
    if hasattr(env.action_space, 'n'):
        action_dim = env.action_space.n  # 離散アクション
    else:
        action_dim = env.action_space.shape[0]  # 連続アクション（ここでは未対応）

    # ネットワークの初期化
    policy = PolicyNet(obs_dim, action_dim).to(device)
    optimizer = optim.Adam(policy.parameters(), lr=3e-4)  # 学習率は固定

    # ログ & モデル保存ディレクトリ
    base_dir = pathlib.Path(args.experiment_dir) / args.experiment_name
    checkpoint_dir = base_dir / "checkpoints"
    checkpoint_dir.mkdir(parents=True, exist_ok=True)

    def save_checkpoint(ep):
        """ チェックポイントをエピソード番号付きで保存 """
        path = checkpoint_dir / f"checkpoint_ep{ep}.pt"
        torch.save(policy.state_dict(), path)
        print(f"[Checkpoint] Model saved to {path}")

    # 推論モード
    if args.inference:
        # モデルロード
        state_dict = torch.load(args.resume_model_path, map_location=device)
        policy.load_state_dict(state_dict)
        policy.eval()
        print("推論モード開始: モデルをロードしました。")

        obs = env.reset()
        for step in range(1, 1001):  # 固定ステップ数推論（例: 1000ステップ）
            with torch.no_grad():
                x = torch.from_numpy(obs).float().to(device)
                logits, _ = policy(x)
                action = torch.argmax(logits, dim=-1).cpu().numpy()
            obs, reward, done, info = env.step(action)
            # 必要ならinfoを表示
            if done:
                obs = env.reset()
        return

    # ----------- トレーニングループ (オンポリシーMC: REINFORCE+バリュー) -----------
    gamma = 0.99  # 割引率
    max_eps = args.max_episodes
    save_every = max_eps // 10  # 10分割チェックポイント保存

    for ep in range(1, max_eps + 1):
        obs = env.reset()
        done = False
        ep_reward = 0.0
        trajectory = []  # 軌跡保管用リスト

        # 1エピソードのデータ収集
        while not done:
            # 状態をTensorに変換
            state_t = torch.from_numpy(obs).float().to(device)
            # フォワードパス
            logits, value = policy(state_t)
            # カテゴリ分布からサンプリング
            dist = torch.distributions.Categorical(logits=logits)
            action = dist.sample()
            logp = dist.log_prob(action)

            # 環境ステップ
            obs_next, reward, done, info = env.step(action.cpu().numpy())

            # 軌跡に保存
            trajectory.append((obs, action.item(), reward, obs_next, done, logp.item(), value.item()))
            obs = obs_next
            ep_reward += reward

        # 収集したエピソードから学習
        # 1) 割引累積報酬の計算
        returns = []
        G = 0.0
        for (_, _, r, _, _, _, _) in reversed(trajectory):
            G = r + gamma * G
            returns.insert(0, G)
        returns = torch.tensor(returns, dtype=torch.float32).to(device)

        # 2) ロス計算
        policy_losses = []
        value_losses  = []
        for (s, a, r, s_next, d, logp_old, v_old), Gt in zip(trajectory, returns):
            s_t = torch.from_numpy(s).float().to(device)
            logits, value = policy(s_t)
            dist = torch.distributions.Categorical(logits=logits)

            # アドバンテージ = Gt - V(s)
            advantage = Gt - value
            # ポリシーロス: -logπ(a|s) * advantage
            policy_losses.append(-dist.log_prob(torch.tensor(a, device=device)) * advantage.detach())
            # バリューロス: MSE
            value_losses.append((value - Gt).pow(2))

        loss = torch.stack(policy_losses).mean() + 0.5 * torch.stack(value_losses).mean()

        # 3) パラメータ更新
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        # エピソード完了のログ
        print(f"Episode {ep}/{max_eps}  Reward: {ep_reward:.2f}  Loss: {loss.item():.4f}")

        # 定期チェックポイント保存
        if ep % save_every == 0:
            save_checkpoint(ep)

    # 学習完了後の最終モデル保存
    final_path = base_dir / "final_model.pt"
    torch.save(policy.state_dict(), final_path)
    print(f"[Done] Training complete. Final model saved to {final_path}")

if __name__ == '__main__':
    main()
