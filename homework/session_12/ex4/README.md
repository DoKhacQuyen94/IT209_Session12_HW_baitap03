# Bài 4: Tự động triển khai ứng dụng Spring Boot (Container) lên VPS từ xa qua SSH

## 1. Mục tiêu
- **Tự động hóa đóng gói Container**: Tự động build Docker Image và đẩy lên **GitHub Container Registry (GHCR)** mỗi khi có commit mới trên nhánh `main`.
- **Tự động hóa triển khai từ xa (Remote Deployment)**: Sử dụng GitHub Action chính thức `appleboy/ssh-action@v1.0.3` để thiết lập phiên SSH bảo mật đến máy chủ VPS từ xa.
- **Quản lý vòng đời Container trên VPS**: Tự động kéo image mới nhất, dừng và hủy bỏ container cũ (zero-breakage rollback), khởi chạy lại container phiên bản mới trên cổng `8080:8080`.

---

## 2. Cấu trúc thư mục nộp bài
```text
homework/session_12/ex4/
├── .github/
│   └── workflows/
│       └── deploy-vps.yml      # Workflow CI/CD build image & SSH deploy VPS
└── README.md                   # Báo cáo kỹ thuật chi tiết & hướng dẫn kiểm thử
```

---

## 3. Khai báo Repository Secrets trên GitHub

Truy cập repository trên GitHub: **Settings** ➔ **Secrets and variables** ➔ **Actions** ➔ **Repository secrets** và thêm 3 biến bí mật:

| Tên Secret | Ý nghĩa | Ví dụ giá trị |
| :--- | :--- | :--- |
| **`SSH_HOST`** | Địa chỉ IP công khai hoặc tên miền của máy chủ VPS | `103.90.227.15` |
| **`SSH_USER`** | Tên tài khoản người dùng đăng nhập VPS qua SSH | `root` hoặc `ubuntu` |
| **`SSH_KEY`** | Khóa bí mật (Private SSH Key) tương ứng trên máy chủ VPS | `-----BEGIN OPENSSH PRIVATE KEY----- ...` |

> [!TIP]
> Đảm bảo khóa công khai (`id_rsa.pub`) đã được cấu hình trong tệp `~/.ssh/authorized_keys` trên máy chủ VPS và tài khoản người dùng có quyền thực thi lệnh `docker` (hoặc nằm trong nhóm `docker`).

---

## 4. Kịch bản Workflow `.github/workflows/deploy-vps.yml`

```yaml
name: Build and Deploy to Remote VPS via SSH

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: app

jobs:
  build-image:
    name: Build & Push Docker Image
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry (GHCR)
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ github.repository_owner }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ github.repository_owner }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy-vps:
    name: Deploy to VPS via SSH
    runs-on: ubuntu-latest
    needs: build-image

    steps:
      - name: Thực thi câu lệnh triển khai trên VPS qua SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            echo "=========================================="
            echo "1. Đăng nhập vào GitHub Container Registry..."
            echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

            echo "2. Kéo Image mới nhất: docker pull ghcr.io/${{ github.repository_owner }}/app:latest..."
            docker pull ghcr.io/${{ github.repository_owner }}/app:latest

            echo "3. Khởi chạy lại container: dừng và xóa container cũ..."
            docker stop app || true
            docker rm app || true

            echo "4. Khởi chạy container mới trên cổng 8080:8080..."
            docker run -d --name app -p 8080:8080 ghcr.io/${{ github.repository_owner }}/app:latest

            echo "5. Kiểm tra trạng thái container đang chạy..."
            docker ps --filter "name=app"
            echo "Triển khai lên VPS thành công!"
            echo "=========================================="
```

---

## 5. Quy trình thực thi & Kiểm tra kết quả

### 5.1. Giám sát log thực thi trên GitHub Actions
1. Vào tab **Actions** trên GitHub Repository.
2. Chọn lần chạy workflow **Build and Deploy to Remote VPS via SSH**.
3. Quan sát 2 Job tuần tự:
   - **Job 1 (`build-image`)**: Đóng gói mã nguồn thành Docker Image và đẩy thành công lên `ghcr.io`.
   - **Job 2 (`deploy-vps`)**: Kết nối SSH tới `SSH_HOST`, thực hiện đăng nhập GHCR, kéo image và khởi chạy lại container với port `8080:8080`.

### 5.2. Kiểm tra trực tiếp trên trình duyệt
1. Mở trình duyệt web và truy cập endpoint Actuator Health:
   ```text
   http://<VPS_IP>:8080/actuator/health
   ```
2. **Kết quả mong đợi**:
   - Trả về mã trạng thái HTTP `200 OK`.
   - Dữ liệu phản hồi dạng JSON:
     ```json
     {
       "status": "UP",
       "details": {
         "diskSpace": { "status": "UP" },
         "ping": { "status": "UP" }
       }
     }
     ```
3. Truy cập trang chủ `http://<VPS_IP>:8080`:
   - Xác nhận ứng dụng container đang hoạt động bình thường trên VPS.
