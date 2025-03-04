FROM python:3.8-slim

# 必要なパッケージをインストールします
RUN apt-get update && apt-get install -y tar

# 作業ディレクトリを設定する
WORKDIR /app

# Pythonスクリプトをイメージにコピーする
COPY 02_extract_files.py /app/extract_files.py

# Pythonスクリプトを実行するコマンドを設定する
CMD ["python", "/app/extract_files.py"]