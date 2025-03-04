FROM python:3.8-slim

# �K�v�ȃp�b�P�[�W���C���X�g�[�����܂�
RUN apt-get update && apt-get install -y tar

# ��ƃf�B���N�g����ݒ肷��
WORKDIR /app

# Python�X�N���v�g���C���[�W�ɃR�s�[����
COPY 02_extract_files.py /app/extract_files.py

# Python�X�N���v�g�����s����R�}���h��ݒ肷��
CMD ["python", "/app/extract_files.py"]