# Golang開発環境用Dockerfile(サイズ最適化版・Podman対応・軽量ベース版)
#
# 変更点(2026 fall):
# - ベースイメージを mcr.microsoft.com/devcontainers/base:trixie から
#   debian:trixie-slim に変更(common-utils/gitフィーチャーの766MBを排除)
# - vscodeユーザーはdevcontainer featureに頼らず自前で作成
# - gitはDebian trixieのaptパッケージ版(ソースビルドしない)
# - zsh/oh-my-zshは導入しない(bashのみ)
# - COPY時に --chown を指定し、後段の chown -R による二重コピー(約92MB)を排除
#
# ビルド方法:
#   podman system prune -a -f --volumes  # 初回推奨
#   podman build --format docker --no-cache \
#     --tag ghcr.io/onisi/omu-sss-websys:latest \
#     --tag ghcr.io/onisi/omu-sss-websys:2026fall .

FROM debian:trixie-slim AS builder

ENV GO_VERSION=1.25.12 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    wget -q -O "/tmp/go${GO_VERSION}.linux-amd64.tar.gz" \
        "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "/tmp/go${GO_VERSION}.linux-amd64.tar.gz" && \
    rm -f "/tmp/go${GO_VERSION}.linux-amd64.tar.gz"

ENV PATH=/usr/local/go/bin:$PATH \
    GOPATH=/tmp/gotools \
    CGO_ENABLED=0

# 注意: gopls / dlv はビルド時点の @latest を使用(要バージョン固定検討)
RUN go install -ldflags="-s -w" golang.org/x/tools/gopls@latest && \
    go install -ldflags="-s -w" github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.12.2 && \
    go install -ldflags="-s -w" golang.org/x/tools/cmd/goimports@latest && \
    go install -ldflags="-s -w" github.com/go-delve/delve/cmd/dlv@latest && \
    go clean -cache -modcache -testcache && \
    rm -rf /tmp/gotools/pkg /tmp/gotools/src

# 最終ステージ(最小構成・debian:trixie-slimベース)
FROM debian:trixie-slim

LABEL maintainer="onisi@omu.ac.jp" \
      description="Size-optimized Golang development environment (slim base)" \
      version="26.1.0-slim" \
      base-os="debian-trixie-slim" \
      go-version="1.25.12" \
      org.opencontainers.image.source="https://github.com/onisi/golang-26" \
      org.opencontainers.image.licenses="MIT"

ARG GO_VERSION=1.25.12

ENV GOPATH=/go \
    GOBIN=/go/bin \
    PATH=/usr/local/go/bin:/go/bin:$PATH \
    TZ=Asia/Tokyo \
    LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    GOCACHE=/home/vscode/.cache/go-build \
    GOTOOLCHAIN=local \
    CGO_ENABLED=0

# vscodeユーザーを先に作成(この後のCOPY --chownで参照するため)
RUN groupadd --gid 1000 vscode && \
    useradd --uid 1000 --gid 1000 -m -s /bin/bash vscode

# Goとツールをコピー(--chownで所有者を指定し、後段のchown -Rによる二重コピーを回避)
COPY --from=builder --chown=vscode:vscode /usr/local/go /usr/local/go
COPY --from=builder --chown=vscode:vscode /tmp/gotools/bin/* /go/bin/

# 必要最小限のパッケージのみインストール
# (common-utils/gitフィーチャーの代替。gitはaptのDebian標準版を使用、zshは導入しない)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo git make ca-certificates \
        tzdata locales \
        curl wget vim-tiny && \
    # ロケール設定(最小限)
    echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen ja_JP.UTF-8 && \
    # タイムゾーン設定
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # sudoers設定
    echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode && \
    # 徹底的なクリーンアップ
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /tmp/* \
           /var/tmp/* \
           /var/cache/apt/* \
           /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/locale/* \
           /var/log/* && \
    # 不要なファイルの削除
    find /usr/share -type f -name "*.pyc" -delete && \
    find /usr/share -type d -name "__pycache__" -delete

# ディレクトリ作成と所有権設定(/go はCOPY時点で既にvscode所有のため対象から除外)
RUN mkdir -p /go/pkg/mod /workspaces /home/vscode/.cache/go-build && \
    chown -R vscode:vscode /workspaces /home/vscode/.cache && \
    chmod -R 755 /workspaces

USER vscode
WORKDIR /workspaces

# modernc.org/sqlite(CGo不要な純Go実装のSQLiteドライバ)を事前にGOMODCACHEへ
# ダウンロードしておく。devcontainer.jsonの go-mod-cache 名前付きボリュームは、
# 学生の初回Codespace作成時(ボリュームが空の状態)にイメージ内容がそのまま
# コピーされるため、ここで温めておいたキャッシュがそのまま使われ、
# 学生側での初回 `go get` のダウンロード待ちが発生しない。
# 既にボリュームが存在する学生には自動反映されない点に注意。
RUN mkdir -p /tmp/sqlite-prefetch && \
    cd /tmp/sqlite-prefetch && \
    go mod init prefetch && \
    go get modernc.org/sqlite@latest && \
    cd / && rm -rf /tmp/sqlite-prefetch

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD go version && gopls version || exit 1

CMD ["/bin/bash"]
