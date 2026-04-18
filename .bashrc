alias wandb='uvx wandb'
if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi
export PATH="$HOME/.local/bin:$PATH"
if [[ "$(uname -s)" == "Linux" ]]; then
  export MUJOCO_GL=egl
fi
