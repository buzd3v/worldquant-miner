# Báo cáo Phân tích Repository `naive-ollama`

Báo cáo này cung cấp một cái nhìn tổng quan và chi tiết về repository `naive-ollama`, bao gồm mục đích, kiến trúc, cách hoạt động của các thành phần thông qua Docker, và chức năng của từng file Python.

## 1. Tổng quan về Repository (Dựa trên `README.md`)

Repository `naive-ollama` là một hệ thống phức tạp được thiết kế để **tự động tạo, kiểm tra và gửi các yếu tố alpha tài chính** cho nền tảng WorldQuant Brain.

Điểm cốt lõi của hệ thống này là nó thay thế việc sử dụng các API LLM trên nền tảng đám mây (như Kimi trước đây) bằng một giải pháp **chạy mô hình ngôn ngữ lớn (LLM) ngay tại local** thông qua **Ollama**. Điều này mang lại hiệu suất tốt hơn, khả năng kiểm soát cao hơn và bảo mật dữ liệu.

**Các tính năng chính:**

*   **Tích hợp LLM Local**: Sử dụng Ollama với các mô hình như `llama3.2:3b` hoặc `llama2:7b`.
*   **Hỗ trợ GPU**: Tận dụng sức mạnh của GPU NVIDIA để tăng tốc độ xử lý của LLM.
*   **Web Dashboard**: Cung cấp một giao diện web để theo dõi và điều khiển hệ thống trong thời gian thực.
*   **Tự động hóa**: Một "bộ điều phối" (Orchestrator) tự động chạy các quy trình tạo, khai thác và gửi alpha.
*   **Tích hợp WorldQuant Brain**: Giao tiếp trực tiếp với API của WorldQuant để kiểm tra và gửi alpha.
*   **Hỗ trợ Docker**: Dễ dàng triển khai toàn bộ hệ thống bằng Docker và Docker Compose.

**Kiến trúc hệ thống** bao gồm các thành phần chính:
1.  **Alpha Generator (Ollama)**: Tạo ra các ý tưởng alpha mới bằng LLM.
2.  **Alpha Orchestrator (Python)**: Lên lịch và điều phối các hoạt động.
3.  **Web Dashboard (Flask)**: Giao diện người dùng để giám sát.
4.  **WorldQuant API**: Điểm cuối để kiểm tra và gửi các alpha.

## 2. Phân tích Cấu hình Docker (`docker-compose.*.yml`)

Repository này sử dụng Docker Compose để quản lý các dịch vụ. Có 3 file cấu hình chính: `docker-compose.yml` (cho CPU), `docker-compose.gpu.yml` (cho GPU), và `docker-compose.prod.yml` (cho môi trường production). Các file này định nghĩa cách các container (dịch vụ) được xây dựng và chạy cùng nhau.

**Các dịch vụ chính:**

1.  **`ollama-gpu` / `ollama-cpu`**:
    *   **Mục đích**: Đây là dịch vụ cốt lõi chạy **Ollama server**. Nó chịu trách nhiệm tải và phục vụ các mô hình ngôn ngữ lớn (LLM).
    *   **Cấu hình**:
        *   Sử dụng image `ollama/ollama`.
        *   Trong `docker-compose.gpu.yml`, dịch vụ này được cấu hình để sử dụng tài nguyên GPU (`deploy: resources: reservations: devices: [capability: gpu]`), cho phép tăng tốc đáng kể.
        *   Mount một volume (`ollama_data`) để lưu trữ các mô hình LLM đã tải về.
        *   Mở port `11434` để các dịch vụ khác có thể giao tiếp với Ollama API.

2.  **`naive-ollama-gpu` / `naive-ollama-cpu`**:
    *   **Mục đích**: Đây là container chính chạy **ứng dụng Python** của dự án (bộ điều phối, trình tạo alpha, dashboard, v.v.).
    *   **Cấu hình**:
        *   Build từ `Dockerfile` hoặc `Dockerfile.prod`.
        *   Phụ thuộc vào dịch vụ `ollama-gpu` hoặc `ollama-cpu` để đảm bảo Ollama khởi động trước.
        *   Mount nhiều volume quan trọng:
            *   `.:/app`: Ánh xạ toàn bộ mã nguồn của dự án vào container, cho phép thay đổi code mà không cần build lại image.
            *   `./results:/app/results`: Lưu kết quả các alpha đã tạo.
            *   `./logs:/app/logs`: Lưu file log của ứng dụng.
            *   `./credential.txt:/app/credential.txt`: Cung cấp file chứa thông tin đăng nhập WorldQuant một cách an toàn.
        *   Sử dụng `network_mode: service:ollama-gpu` (hoặc cpu) để container này có thể truy cập Ollama server qua `localhost`, đơn giản hóa việc kết nối.

3.  **`ollama-webui`**:
    *   **Mục đích**: Cung cấp một **giao diện web** thân thiện để quản lý Ollama, cho phép người dùng chat với các mô hình, tải/xóa mô hình, v.v.
    *   **Cấu hình**:
        *   Sử dụng image `ghcr.io/ollama-webui/ollama-webui:main`.
        *   Kết nối với Ollama server qua `host.docker.internal` hoặc tên dịch vụ.
        *   Mở port `3000` (trong `docker-compose.gpu.yml`) hoặc `8080` (trong `docker-compose.yml`) để truy cập giao diện.

4.  **`alpha-dashboard`**:
    *   **Mục đích**: Chạy **Flask Web Dashboard** (`web_dashboard.py`).
    *   **Cấu hình**:
        *   Build từ cùng một Dockerfile với ứng dụng chính.
        *   Chạy một lệnh khác (`CMD ["python", "web_dashboard.py"]`).
        *   Mở port `5000` để người dùng truy cập dashboard.

**Sự khác biệt giữa các file:**
*   `docker-compose.yml`: Cấu hình cơ bản cho môi trường **CPU**.
*   `docker-compose.gpu.yml`: Mở rộng từ file cơ bản, **thêm hỗ trợ GPU** cho dịch vụ Ollama và ứng dụng chính. Đây là cấu hình được khuyến nghị.
*   `docker-compose.prod.yml`: Cấu hình cho môi trường **production**. Nó build từ `Dockerfile.prod` (có thể tối ưu hơn) và thường không mount mã nguồn trực tiếp để đảm bảo tính ổn định.

## 3. Phân tích Chi tiết các File Python

Đây là phần phân tích sâu về logic hoạt động của từng file Python chính.

*   **`alpha_generator_ollama.py`**:
    *   **Mục đích**: Đây là **trái tim của hệ thống**, chịu trách nhiệm tạo ra các biểu thức alpha.
    *   **Logic hoạt động**:
        1.  Định nghĩa các prompt (câu lệnh) chi tiết để yêu cầu LLM tạo ra các công thức alpha dựa trên các quy tắc và ví dụ cho trước.
        2.  Hàm `generate_alpha_expressions` gửi yêu cầu đến Ollama API (`http://localhost:11434/api/generate`) với prompt đã chuẩn bị.
        3.  Nó nhận phản hồi từ LLM, sau đó sử dụng regex để trích xuất các biểu thức alpha từ văn bản mà LLM tạo ra.
        4.  Sử dụng thư viện `wqbrain` để đăng nhập vào WorldQuant Brain và kiểm tra (simulate) các alpha vừa tạo.
        5.  Lưu kết quả (thành công hay thất bại, thông số chi tiết) vào các file trong thư mục `results/`.

*   **`alpha_orchestrator.py`**:
    *   **Mục đích**: **Bộ điều phối trung tâm**, tự động hóa và lên lịch cho các tác vụ.
    *   **Logic hoạt động**:
        1.  Sử dụng thư viện `schedule` để chạy các công việc theo một lịch trình định sẵn.
        2.  Nó gọi hàm `generate_and_test_alphas` từ `alpha_generator_ollama.py` theo một chu kỳ (ví dụ: mỗi 6 giờ) để liên tục tạo alpha mới.
        3.  Nó cũng gọi hàm `mine_expressions` từ `alpha_expression_miner.py` để tìm kiếm các biến thể alpha mới.
        4.  Chạy một vòng lặp vô hạn (`while True`) để đảm bảo các tác vụ theo lịch trình được thực thi liên tục.

*   **`web_dashboard.py`**:
    *   **Mục đích**: Cung cấp **giao diện web giám sát** và điều khiển.
    *   **Logic hoạt động**:
        1.  Đây là một ứng dụng web được xây dựng bằng **Flask**.
        2.  Định nghĩa các route (đường dẫn URL):
            *   `/`: Hiển thị trang dashboard chính (`dashboard.html`).
            *   `/status`: Cung cấp dữ liệu trạng thái (GPU, Ollama, Orchestrator, WorldQuant) dưới dạng JSON để frontend cập nhật.
            *   `/log`: Đọc và trả về nội dung của các file log.
            *   `/generate_alpha`, `/mine_alphas`, `/submit_alphas`: Các endpoint API để người dùng có thể kích hoạt các hành động tương ứng từ giao diện web.
        3.  Các hàm trong file này sẽ gọi lại các chức năng tương ứng từ các file Python khác (ví dụ: gọi `generate_and_test_alphas` khi người dùng nhấn nút "Generate Alpha").

*   **`alpha_expression_miner.py`**:
    *   **Mục đích**: **Khai thác biểu thức alpha**, tức là tìm kiếm các biến thể mới từ những alpha đã thành công.
    *   **Logic hoạt động**:
        1.  Đọc các file kết quả trong thư mục `results/` để tìm những alpha có hiệu suất tốt.
        2.  Sử dụng các kỹ thuật biến đổi (ví dụ: thay đổi toán tử, tham số) để tạo ra các biểu thức alpha mới dựa trên những cái thành công.
        3.  Kiểm tra các alpha biến thể này với WorldQuant Brain. Đây là một cách thông minh để tối ưu hóa và tìm kiếm các alpha tốt hơn thay vì chỉ dựa vào LLM.

*   **`improved_alpha_submitter.py`**:
    *   **Mục đích**: Tự động **gửi các alpha tốt nhất** lên WorldQuant Brain.
    *   **Logic hoạt động**:
        1.  Quét thư mục `results/` để tìm các alpha có trạng thái "passed" (đã qua mô phỏng) và có các chỉ số hiệu suất tốt (ví dụ: Sharpe ratio cao).
        2.  Thực hiện việc gửi (submit) các alpha này thông qua API của `wqbrain`.
        3.  Có cơ chế giới hạn tỷ lệ (rate limiting) để đảm bảo không gửi quá nhiều alpha trong một ngày, tuân thủ quy định của WorldQuant.

*   **`vram_monitor.py`**:
    *   **Mục đích**: Theo dõi việc sử dụng VRAM của GPU.
    *   **Logic hoạt động**: Sử dụng thư viện `pynvml` (NVIDIA Management Library) để truy vấn thông tin về GPU, bao gồm tổng bộ nhớ, bộ nhớ đã sử dụng, và nhiệt độ. Dữ liệu này được `web_dashboard.py` sử dụng để hiển thị trên giao diện.

*   **`health_check.py`**:
    *   **Mục đích**: Kiểm tra "sức khỏe" của các dịch vụ phụ thuộc.
    *   **Logic hoạt động**: Thực hiện các kiểm tra đơn giản như gửi một yêu cầu đến Ollama API và API của WorldQuant để đảm bảo chúng đang hoạt động và có thể kết nối.

## 4. Kết luận

Repository `naive-ollama` là một hệ thống tự động hóa toàn diện và mạnh mẽ cho việc nghiên cứu tài chính định lượng. Bằng cách kết hợp LLM chạy local (Ollama), tự động hóa (Python), và khả năng triển khai dễ dàng (Docker), nó tạo ra một quy trình làm việc hiệu quả từ khâu lên ý tưởng, kiểm tra, tối ưu hóa, cho đến gửi sản phẩm cuối cùng là các alpha tài chính. Kiến trúc được module hóa rõ ràng, giúp dễ dàng bảo trì và mở rộng.