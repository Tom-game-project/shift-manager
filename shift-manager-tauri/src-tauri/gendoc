#!/bin/bash
set -e # エラーが起きたら即座に中断

# --- 設定 ---
# ホスト側（あなたのPC）での名前
WORKDIR="work_docs"
DB_NAME="temp_schema.db"
MIGRATIONS="./migrations"
OUTPUT_DIR="dbdoc"

# 1. きれいな状態から始める
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# 2. SQLite DBの構築 (ホスト側で実行)
# マイグレーションファイルを辞書順にすべて流し込む
for sql in $(ls "$MIGRATIONS"/*.sql | sort); do
    echo "Applying: $sql"
    sqlite3 "$WORKDIR/$DB_NAME" < "$sql"
done

# 3. tblsでドキュメント生成 (Dockerで実行)
# ポイント：$WORKDIRをコンテナ内の /work にマウントする
# コンテナ内のtblsから見ると、DBは /work/temp_schema.db にある
sudo docker run --rm \
  --user $(id -u):$(id -g) \
  -v "$PWD/$WORKDIR:/work" \
  -w /work \
  ghcr.io/k1low/tbls doc sqlite:///work/$DB_NAME

# 4. 生成されたドキュメントをカレントディレクトリに移動（必要なら）
# tblsはデフォルトで /work/dbdoc に出力するので、ホストの $WORKDIR/dbdoc にできている
# mv "$WORKDIR/$OUTPUT_DIR"./"$OUTPUT_DIR"

# 5. 後片付け：一時DBを消す
rm -rf "$WORKDIR"

# echo "Success! Documentation generated in./$OUTPUT_DIR"
echo "Done !"
