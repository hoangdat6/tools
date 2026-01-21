# 🚀 Upload CIC Parquet lên S3 - Chỉ dùng AWS CLI

**Không cần Python!** Chỉ cần AWS CLI.

## Cách 1: Nhanh nhất (Dùng .env)

```bash
# 1. Tạo file .env
cp .env.example .env

# 2. Sửa tên bucket trong .env
nano .env
# Đổi: BUCKET_NAME=ten-bucket-cua-ban

# 3. Chạy
./quick_start.sh
```

## Cách 2: Chạy trực tiếp

```bash
./simple_upload.sh --bucket ten-bucket-cua-ban
```

## Các tùy chọn

```bash
# Chỉ upload (bucket đã có sẵn)
./simple_upload.sh --bucket my-bucket --no-create-bucket

# Đổi region
./simple_upload.sh --bucket my-bucket --region ap-southeast-1

# Đổi prefix trong S3
./simple_upload.sh --bucket my-bucket --prefix data/cic

# Bật versioning
./simple_upload.sh --bucket my-bucket --enable-versioning

# Tất cả tùy chọn
./simple_upload.sh \
  --bucket my-bucket \
  --region ap-southeast-1 \
  --prefix data/cic \
  --local-path ./cicflow_parquet \
  --enable-versioning
```

## Kiểm tra sau khi upload

```bash
# Xem files
aws s3 ls s3://ten-bucket/cic_parquet/ --recursive

# Xem dung lượng
aws s3 ls s3://ten-bucket/cic_parquet/ --recursive --summarize --human-readable
```

## Troubleshooting

### "Bucket name already exists"
→ Đổi tên bucket (phải unique toàn cầu)

### "Access Denied"
→ Chạy: `aws configure`

### "AWS CLI not found"
→ Cài đặt: `sudo apt install awscli` hoặc xem https://aws.amazon.com/cli/

---

**Lưu ý**: Script `simple_upload.sh` chỉ dùng AWS CLI, không cần Python hay pip3!
