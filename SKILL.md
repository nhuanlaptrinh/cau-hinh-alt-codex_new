---
name: cau-hinh-alt-codex
description: Cài đặt, sửa hoặc đổi đồng bộ model Codex Extension/Codex CLI và OpenClaw qua ALT/9Router trên Windows, Linux, macOS hoặc VPS. Use khi cần chọn GPT-5.6-sol/GPT-5.6-terra/GPT-5.6-luna, cập nhật user config của Codex, đổi model mặc định hoặc model ghim theo agent trong OpenClaw, kiểm tra /v1/models, backup config, hoặc xử lý lỗi provider/model mà không làm lộ API key.
---

# Cấu Hình Codex Qua ALT Gateway Đa Nền Tảng

## Mục Tiêu

Cấu hình Codex Extension trong Antigravity và Codex CLI trên máy khác theo mẫu đang dùng trên VPS:

```toml
model_provider = "alt"
model = "GPT-5.6-sol"
model_reasoning_effort = "medium"

[model_providers.alt]
name = "ALT"
base_url = "https://codex.anhlaptrinh.vn/v1"
env_key = "ALT_KEY"
```

Trường hợp cấu hình Codex Extension: API key được cập nhật trực tiếp vào file `auth.json` (hai file `auth.json` và `config.toml` luôn nằm cùng folder với `SKILL.md`) theo định dạng `{"OPENAI_API_KEY": "<API_KEY>"}` rồi copy trực tiếp vào thư mục `.codex` (`%USERPROFILE%\.codex` hoặc `$CODEX_HOME`), không cần tạo hay thiết lập biến môi trường hệ thống. API key không ghi trực tiếp vào `config.toml`.

## Quy Tắc Đường Dẫn Mềm

- Không giả định VPS chạy bằng `root`, không ghi cứng tên user, ổ đĩa, thư mục cài skill hoặc thư mục backup.
- Luôn ưu tiên biến môi trường/tùy chọn do người dùng cung cấp, sau đó mới dùng thư mục home của user đang chạy.
- Thư mục skill là thư mục thực tế chứa `SKILL.md`; dùng `<skill-dir>`, biến `ALT_CODEX_SKILL_DIR` hoặc working directory đã được xác minh thay vì chép một đường dẫn máy cụ thể.
- Codex config mặc định: `${CODEX_HOME:-$HOME/.codex}/config.toml` trên shell; trên PowerShell dùng `$env:CODEX_HOME` nếu có, nếu không dùng `Join-Path $env:USERPROFILE ".codex"`.
- OpenClaw config mặc định: `${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}`. Khi layout khác, lấy đường dẫn thực tế từ người dùng hoặc config/runtime hiện tại.
- Backup mặc định của script: `${ALT_CODEX_BACKUP_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/cau-hinh-alt-codex/backups}`; có thể ghi đè bằng `ALT_CODEX_BACKUP_DIR` hoặc `--backup-dir`.
- Trước khi đọc, copy hoặc sửa file, luôn hiển thị/xác minh đường dẫn đã resolve và dừng nếu file nằm ngoài tài khoản hoặc VPS mục tiêu.

## Model Được Hỗ Trợ

Skill chỉ được cấu hình một trong ba model sau:

- `GPT-5.6-sol`: model mặc định khi người dùng không yêu cầu model cụ thể.
- `GPT-5.6-terra`: dùng khi người dùng yêu cầu model này hoặc một cách viết tương đương.
- `GPT-5.6-luna`: dùng khi người dùng yêu cầu model này hoặc một cách viết tương đương.

Nhận diện tên model không phân biệt chữ hoa/chữ thường. Chấp nhận dấu gạch ngang hoặc khoảng trắng giữa các phần của tên model, đồng thời bỏ khoảng trắng thừa trước khi so khớp. Ví dụ:

- `GPT-5.6-luna`, `gpt-5.6-luna`, `GPT-5.6-LUNA` và `gpt 5.6 luna` đều phải được hiểu là `GPT-5.6-luna`.
- `GPT-5.6-terra`, `gpt-5.6-terra` và `gpt 5.6 terra` đều phải được hiểu là `GPT-5.6-terra`.
- `GPT-5.6-sol`, `gpt-5.6-sol` và `gpt 5.6 sol` đều phải được hiểu là `GPT-5.6-sol`.

Sau khi nhận diện, luôn chuẩn hóa và ghi tên chính thức vào `config.toml`: `GPT-5.6-sol`, `GPT-5.6-terra` hoặc `GPT-5.6-luna`. Không ghi nguyên cách viết chữ thường hoặc cách viết có khoảng trắng của người dùng vào file.

Khi người dùng yêu cầu `GPT-5.6-terra`, `GPT-5.6-luna` hoặc cách viết tương đương, cập nhật khóa `model` trong `config.toml` thành tên chính thức tương ứng. Nếu dùng bộ file mẫu đi kèm skill, copy file theo workflow rồi chỉ đổi khóa `model`, không thay đổi các cấu hình không liên quan.

Nếu người dùng yêu cầu bất kỳ model nào ngoài ba model trên, không cập nhật cấu hình và không tự động thay thế bằng model gần giống. Hãy thông báo rằng hiện tại chỉ hỗ trợ `GPT-5.6-sol`, `GPT-5.6-terra` và `GPT-5.6-luna`, rồi yêu cầu họ chọn một trong ba model này.

## Chính Sách Chọn Model

- `GPT-5.6-sol`: mặc định cân bằng cho coding/agent phức tạp; dùng khi người dùng không chỉ định model.
- `GPT-5.6-terra`: lựa chọn cân bằng tốc độ và chất lượng cho công việc hằng ngày.
- `GPT-5.6-luna`: ưu tiên tốc độ và chi phí cho tác vụ nhẹ.
- Codex ghi model dạng `GPT-5.6-*`.
- OpenClaw dùng provider/model dạng `<provider-hien-tai>/GPT-5.6-*`. Prefix provider có thể là `9r`, `9k`, `8r`, `8k` hoặc tên khác; phải đọc cấu hình hiện tại, không được hardcode.
- Khi cài mới, sửa provider hoặc đồng bộ VPS/OpenClaw, xác minh model xuất hiện trong endpoint `/v1/models` của gateway đang dùng. Riêng yêu cầu chỉ đổi model trên máy tính thì không test gateway trừ khi người dùng yêu cầu.

## Chỉ Đổi Model Trên Máy Tính

Áp dụng workflow này khi người dùng chỉ yêu cầu đổi model Codex trên máy tính, ví dụ “đổi sang GPT-5.6-terra”, mà không yêu cầu đồng bộ VPS, đổi OpenClaw, copy bộ file mẫu, đổi API key hoặc kiểm tra gateway.

1. Chuẩn hóa model theo mục **Model Được Hỗ Trợ**. Nếu model không nằm trong ba model được hỗ trợ, dừng trước khi sửa file.
2. Resolve `config.toml` của user hiện tại bằng `$CODEX_HOME` hoặc thư mục `.codex` trong home; không dùng file `config.toml` nằm cạnh `SKILL.md` nếu người dùng không yêu cầu copy bộ file mẫu.
3. Backup `config.toml` hiện tại với timestamp trước khi ghi nếu file đã tồn tại.
4. Chỉ cập nhật khóa top-level `model` thành tên chính thức `GPT-5.6-sol`, `GPT-5.6-terra` hoặc `GPT-5.6-luna`; giữ nguyên `model_provider`, `model_reasoning_effort`, `[model_providers.*]`, `[projects.*]`, MCP và mọi cấu hình khác.
5. Không đọc/sửa `auth.json`, không copy file, không sửa OpenClaw, không restart gateway/Antigravity và không test `/v1/models` trừ khi người dùng yêu cầu riêng.
6. Sau khi ghi, chỉ xác nhận `config.toml` tồn tại và khóa `model` đã nhận đúng giá trị; báo cáo đường dẫn thực tế và model mới, không in secret.

Ví dụ resolve và sửa trực tiếp trên Linux/macOS/VPS:

```bash
codex_home="${CODEX_HOME:-$HOME/.codex}"
config_path="$codex_home/config.toml"
selected_model="GPT-5.6-terra"
stamp=$(date +%Y%m%d-%H%M%S)

test -f "$config_path" || { echo "Không tìm thấy: $config_path" >&2; exit 1; }
cp -p "$config_path" "$config_path.bak-$stamp"
MODEL_VALUE="$selected_model" perl -0pi -e 's/^model\s*=\s*"[^"]*"/model = "$ENV{MODEL_VALUE}"/m or die "Top-level model key not found\n"' "$config_path"
```

Trên Windows PowerShell, resolve `$codexHome` từ `$env:CODEX_HOME` hoặc `$env:USERPROFILE`, tạo backup rồi sửa duy nhất dòng top-level `model` trong `$configPath`. Không thay `$sourceDir`, không copy `auth.json` và không dùng đường dẫn máy cụ thể.

## Đổi Đồng Bộ Trên VPS

Script chuẩn đi kèm skill:

```bash
bash scripts/set_alt_model.sh --model GPT-5.6-sol --dry-run
bash scripts/set_alt_model.sh --model GPT-5.6-sol --all-agents
```

Nếu gọi từ thư mục khác, truyền thư mục skill bằng biến thay vì ghi cứng đường dẫn cài đặt:

```bash
export ALT_CODEX_SKILL_DIR="<skill-dir>"
bash "$ALT_CODEX_SKILL_DIR/scripts/set_alt_model.sh" \
  --model GPT-5.6-sol \
  --all-agents
```

Script thực hiện:

1. Chỉ chấp nhận `GPT-5.6-sol`, `GPT-5.6-terra`, `GPT-5.6-luna` và cách viết tương đương.
2. Backup file vào `${ALT_CODEX_BACKUP_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/cau-hinh-alt-codex/backups}` trước khi ghi; cho phép đổi bằng `ALT_CODEX_BACKUP_DIR` hoặc `--backup-dir`.
3. Chỉ đổi khóa `model` cấp cao trong Codex config; giữ nguyên provider, projects, MCP và cấu hình khác.
4. Tự phát hiện provider từ `agents.defaults.model.primary`, xác nhận provider đó tồn tại trong `models.providers`, rồi đăng ký đủ ba model vào đúng provider.
5. Đổi `agents.defaults.model.primary` và thêm model vào `agents.defaults.models`.
6. Khi có `--all-agents`, chỉ thay các agent đang ghim `codex` hoặc một trong ba model được quản lý thuộc đúng provider vừa phát hiện; không đụng agent dùng provider khác.
7. Validate JSON/OpenClaw sau khi ghi; nếu validation lỗi thì khôi phục backup vừa tạo.
8. Tự động chạy `openclaw gateway restart` và kiểm tra `openclaw gateway status` sau khi sửa config OpenClaw đang hoạt động.

Mặc định script dùng:

- Codex: `${CODEX_HOME:-$HOME/.codex}/config.toml`
- OpenClaw: `${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}`
- Backup: `${ALT_CODEX_BACKUP_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/cau-hinh-alt-codex/backups}`

Có thể chỉ định đường dẫn khác bằng `--codex-config`, `--openclaw-config`, `--backup-dir` hoặc các biến môi trường tương ứng ở trên.

Khi đổi model OpenClaw, gateway sẽ restart tự động sau bước validate. Chỉ dùng tùy chọn dưới đây khi cần chủ động trì hoãn restart:

```bash
bash scripts/set_alt_model.sh \
  --model GPT-5.6-terra \
  --openclaw-only \
  --no-restart-gateway
```

Với `--dry-run`, script chỉ hiển thị rằng gateway sẽ restart và không thực hiện restart.

Script ưu tiên lấy prefix từ model mặc định hiện tại. Ví dụ:

- `9r/codex` sẽ đổi thành `9r/GPT-5.6-sol`.
- `9k/codex` sẽ đổi thành `9k/GPT-5.6-sol`.
- `8r/GPT-5.6-luna` sẽ đổi thành `8r/GPT-5.6-terra` khi chọn terra.
- `8k/codex` sẽ đổi thành `8k/GPT-5.6-luna` khi chọn luna.

Nếu cấu hình không có model mặc định hợp lệ hoặc có nhiều provider không thể xác định duy nhất, script phải dừng và yêu cầu chỉ rõ provider, không được tự đoán:

```bash
bash scripts/set_alt_model.sh \
  --model GPT-5.6-sol \
  --openclaw-provider 9k \
  --all-agents
```

### Chỉ đổi Codex

```bash
bash scripts/set_alt_model.sh --model GPT-5.6-terra --codex-only
```

### Chỉ đổi OpenClaw

```bash
bash scripts/set_alt_model.sh --model GPT-5.6-luna --openclaw-only --all-agents
```

### Kiểm tra sau thay đổi

```bash
codex_config="${CODEX_HOME:-$HOME/.codex}/config.toml"
rg -n '^(model_provider|model|model_reasoning_effort)\s*=' "$codex_config"
openclaw config validate
openclaw models status
```

Không in `auth.json`, API key hoặc toàn bộ `openclaw.json` trong báo cáo.

## Khi Dùng Skill

- Cài Codex Extension trong Antigravity trên Windows, Linux hoặc macOS để chạy qua ALT Gateway.
- Đồng bộ cách cấu hình từ user config Codex trên VPS sang máy khác.
- Sửa lỗi provider, model, endpoint, biến môi trường hoặc lỗi `401`/không kết nối.
- Cấu hình Codex CLI và extension dùng chung user-level config.
- Đổi model giữa `GPT-5.6-sol`, `GPT-5.6-terra` và `GPT-5.6-luna` theo yêu cầu của người dùng.
- Khi người dùng chỉ nói đổi model trên máy tính, sửa trực tiếp khóa `model` trong user `config.toml` theo mục **Chỉ Đổi Model Trên Máy Tính**.
- Đổi cùng một model cho Codex và OpenClaw trên VPS, bao gồm các agent đang ghim model cũ khi người dùng yêu cầu áp dụng toàn bộ.

## Quy Tắc An Toàn

- Không đọc hoặc in toàn bộ file cấu hình nếu file có thể chứa secret; chỉ lấy các khóa cần thiết và che giá trị nhạy cảm.
- Không ghi API key thật vào skill, tài liệu, repo, shell history hoặc câu trả lời cuối.
- `env_key` phải là tên biến môi trường `ALT_KEY`, tuyệt đối không phải API key thật.
- Luôn backup `config.toml` trước khi sửa nếu file đã tồn tại.
- Luôn backup `openclaw.json` trước khi sửa và chạy `openclaw config validate` sau thay đổi.
- Không đổi `imageModel`, fallback hoặc provider khác nếu người dùng chỉ yêu cầu đổi model chat mặc định.
- Không ghi đè các phần cấu hình khác như `[projects]`, MCP, sandbox hoặc trust nếu task không yêu cầu.
- Không yêu cầu người dùng gửi API key vào chat. Cho người dùng tự nhập trực tiếp trên máy.

## Vị Trí Cấu Hình

| Môi trường | Cách resolve user config |
|---|---|
| Windows PowerShell | Dùng `$env:CODEX_HOME` nếu có; nếu không, ghép `$env:USERPROFILE`, `.codex` và `config.toml` bằng `Join-Path` |
| Linux/macOS/VPS | `${CODEX_HOME:-$HOME/.codex}/config.toml` |

VPS chạy user nào thì dùng home của user đó; không thay `$HOME` bằng một home directory cố định. Nếu có `CODEX_HOME`, ưu tiên thư mục đó. Extension và CLI phải chạy dưới cùng tài khoản người dùng để đọc cùng cấu hình và biến môi trường.

## Sao Chép Bộ File Mẫu & Xử Lý API Key Cho Extension

> [!IMPORTANT]
> Hai file `auth.json` và `config.toml` **luôn nằm cùng folder với `SKILL.md`** trong thư mục của skill. Khi tham chiếu hay copy, luôn lấy trực tiếp từ cùng thư mục chứa `SKILL.md`.

Trường hợp cấu hình Codex Extension, khi có API key người dùng cung cấp:
1. Cập nhật API key vào file `auth.json` tại thư mục skill (luôn nằm cùng folder với `SKILL.md`):
   ```json
   {
     "OPENAI_API_KEY": "<API_KEY>"
   }
   ```
2. Copy nguyên trạng hai file (`auth.json` và `config.toml` luôn nằm cùng folder với `SKILL.md`) từ thư mục skill sang thư mục `.codex` của tài khoản đích:
   - `<skill-dir>\auth.json`
   - `<skill-dir>\config.toml`
3. Không cần khởi tạo hay cấu hình biến môi trường hệ thống cho Codex Extension.

Copy hai file vào thư mục `.codex` của tài khoản Windows đích. Với user hiện tại, lấy profile từ `$env:USERPROFILE`; với user khác, dùng profile path do hệ điều hành trả về hoặc do người dùng chỉ định. Không tự ghép ổ đĩa và tên user. Nếu cấu hình user hiện tại và `CODEX_HOME` đã được đặt, ưu tiên `CODEX_HOME`.

Phân biệt rõ yêu cầu cập nhật skill và yêu cầu áp dụng cấu hình:

- Nếu người dùng chỉ yêu cầu cập nhật/chỉnh sửa skill hoặc xem hướng dẫn, chỉ sửa và xác thực skill rồi dừng. Không tạo thư mục `.codex`, không backup, không copy file, không restart ứng dụng và không test gateway.
- Chỉ chạy thao tác copy khi người dùng yêu cầu rõ ràng việc áp dụng, cài đặt hoặc đồng bộ cấu hình lên tài khoản đích.
- `auth.json` có thể chứa thông tin xác thực: không đọc hoặc in nội dung, không đưa vào log/chat, và không commit file này nếu chứa secret.

### Windows PowerShell

Đặt biến `ALT_CODEX_SKILL_DIR` thành thư mục chứa `auth.json`, `config.toml` và `SKILL.md`, hoặc chạy PowerShell ngay trong thư mục skill. Mặc định `$targetProfile` là profile của user đang chạy; khi chọn tài khoản khác, lấy profile path thực tế từ hệ điều hành hoặc từ người dùng.

```powershell
$sourceDir = if ($env:ALT_CODEX_SKILL_DIR) {
    (Resolve-Path -LiteralPath $env:ALT_CODEX_SKILL_DIR).Path
} else {
    (Get-Location).Path
}
if (-not (Test-Path -LiteralPath (Join-Path $sourceDir "SKILL.md") -PathType Leaf)) {
    throw "Không xác định được thư mục skill. Hãy đặt ALT_CODEX_SKILL_DIR hoặc chạy từ thư mục chứa SKILL.md."
}
$targetProfile = $env:USERPROFILE
$codexHome = if (($targetProfile -eq $env:USERPROFILE) -and $env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $targetProfile ".codex"
}
$fileNames = @("auth.json", "config.toml")
$stamp = Get-Date -Format yyyyMMdd-HHmmss

New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
foreach ($fileName in $fileNames) {
    $sourcePath = Join-Path $sourceDir $fileName
    $destinationPath = Join-Path $codexHome $fileName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Không tìm thấy file nguồn: $sourcePath"
    }
    if (Test-Path -LiteralPath $destinationPath -PathType Leaf) {
        Copy-Item -LiteralPath $destinationPath -Destination "$destinationPath.bak-$stamp"
    }
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
}
```

Sau khi chạy, chỉ xác nhận hai file đích tồn tại; không đọc hoặc in giá trị trong `auth.json`. Báo cáo đường dẫn đích thực tế từ `$codexHome`, không giả định tên user hoặc ổ đĩa.

## Workflow Chuẩn

1. Kiểm tra phạm vi yêu cầu. Nếu người dùng chỉ yêu cầu cập nhật skill, sửa và xác thực skill rồi dừng, không áp dụng cấu hình. Nếu họ chỉ yêu cầu đổi model trên máy tính, thực hiện mục **Chỉ Đổi Model Trên Máy Tính** rồi dừng, không chạy workflow copy/đồng bộ phía dưới.
2. Khi được yêu cầu áp dụng, xác định hệ điều hành, tài khoản đích, profile đích và việc user hiện tại có dùng `CODEX_HOME` hay không.
3. Kiểm tra Codex Extension/Codex CLI đã được cài. Không tự cài extension nếu chưa biết đúng extension ID hoặc nguồn cài đặt.
4. Nếu người dùng yêu cầu dùng bộ file đi kèm skill, làm theo mục **Sao Chép Bộ File Mẫu** và copy đúng `auth.json`, `config.toml`.
5. Xác định đường dẫn user config và tạo thư mục `.codex` nếu chưa có.
6. Backup từng file đích đã tồn tại với timestamp trước khi copy hoặc sửa.
7. Chỉ khi người dùng yêu cầu chỉnh thủ công, cập nhật các khóa cần thiết trong `config.toml` và giữ nguyên cấu hình không liên quan.
8. Trường hợp cấu hình Codex Extension: khi có API key, cập nhật vào file `auth.json` (luôn nằm cùng folder với `SKILL.md`) rồi copy cả `auth.json` và `config.toml` sang thư mục `.codex`, không cần tạo biến môi trường hệ thống. Đảm bảo không làm lộ key trong chat/log.
9. Khi người dùng yêu cầu kiểm tra, test endpoint `/v1/models`, rồi restart hoàn toàn Antigravity/Codex Extension.
10. Mở phiên Codex mới và xác nhận provider/model hoạt động.

Khi đổi model, chuẩn hóa cách viết không phân biệt hoa/thường và chấp nhận dấu gạch ngang hoặc khoảng trắng như mô tả ở mục **Model Được Hỗ Trợ**. Chỉ ghi tên chính thức `GPT-5.6-sol`, `GPT-5.6-terra` hoặc `GPT-5.6-luna` vào khóa `model`. Nếu không thể chuẩn hóa yêu cầu thành một trong ba model này, thông báo danh sách model được hỗ trợ và dừng trước khi sửa cấu hình.

## Windows PowerShell

### Tạo thư mục và backup

```powershell
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$configPath = Join-Path $codexHome "config.toml"
New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
if (Test-Path $configPath) {
    Copy-Item $configPath "$configPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
}
notepad $configPath
```

Thêm hoặc cập nhật mẫu cấu hình ở phần **Mục Tiêu**, không xóa các bảng khác.

### Lưu API key cho Codex Extension (Qua file auth.json)

Trường hợp cấu hình Codex Extension, cập nhật API key vào file `auth.json` trong thư mục skill (luôn nằm cùng folder với `SKILL.md`):

```json
{
  "OPENAI_API_KEY": "<API_KEY_CUA_BAN>"
}
```

Sau đó copy file `auth.json` cùng `config.toml` vào thư mục `.codex` (ví dụ `%USERPROFILE%\.codex`). **Không cần tạo biến môi trường hệ thống.**

If saved via environment variables (e.g. for CLI or shared scripts):

```powershell
$secureKey = Read-Host "Nhap ALT API key" -AsSecureString
$plainKey = [System.Net.NetworkCredential]::new("", $secureKey).Password
[Environment]::SetEnvironmentVariable("ALT_KEY", $plainKey, "User")
Remove-Variable plainKey, secureKey
```

Đóng hoàn toàn Antigravity rồi mở lại nếu dùng phương pháp biến môi trường.

### Kiểm tra không lộ key

```powershell
if ([Environment]::GetEnvironmentVariable("ALT_KEY", "User")) { "ALT_KEY=set" } else { "ALT_KEY=missing" }
```

### Test gateway

Chạy trong cửa sổ PowerShell mới sau khi restart terminal:

```powershell
$key = [Environment]::GetEnvironmentVariable("ALT_KEY", "User")
curl.exe -sS -o NUL -w "%{http_code}`n" -H "Authorization: Bearer $key" --max-time 20 "https://codex.anhlaptrinh.vn/v1/models"
Remove-Variable key
```

## Linux

### Tạo thư mục và backup

```bash
codex_home="${CODEX_HOME:-$HOME/.codex}"
config_path="$codex_home/config.toml"
mkdir -p "$codex_home"
[ ! -f "$config_path" ] || cp -a "$config_path" "$config_path.bak-$(date +%Y%m%d-%H%M%S)"
${EDITOR:-nano} "$config_path"
```

### Lưu API key

Nhập ẩn, sau đó thêm dòng export vào file shell profile phù hợp mà không in key ra màn hình:

```bash
read -rsp 'Nhap ALT API key: ' ALT_KEY; echo
export ALT_KEY
```

Để dùng sau khi đăng nhập lại, lưu bằng trình quản lý secret của hệ điều hành nếu có. Nếu buộc phải dùng shell profile, thêm thủ công `export ALT_KEY="..."` vào `~/.bashrc`, `~/.zshrc` hoặc file môi trường của desktop session, đặt quyền file `600`, và không commit file đó.

Antigravity mở từ desktop có thể không đọc `~/.bashrc`. Khi đó đặt biến trong môi trường desktop/login session hoặc khởi động Antigravity từ terminal đã có biến.

### Kiểm tra và test

```bash
[ -n "${ALT_KEY:-}" ] && echo 'ALT_KEY=set' || echo 'ALT_KEY=missing'
status=$(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $ALT_KEY" --max-time 20 'https://codex.anhlaptrinh.vn/v1/models')
printf 'HTTP %s\n' "$status"
```

## macOS

File cấu hình giống Linux: `${CODEX_HOME:-$HOME/.codex}/config.toml`.

Antigravity mở từ Finder/Dock thường không nhận biến chỉ khai báo trong `~/.zshrc`. Dùng Keychain hoặc đặt biến cho GUI session. Cách tạm thời cho phiên đăng nhập hiện tại:

```bash
read -rsp 'Nhap ALT API key: ' ALT_KEY; echo
launchctl setenv ALT_KEY "$ALT_KEY"
unset ALT_KEY
```

Sau đó thoát hoàn toàn và mở lại Antigravity. Kiểm tra tên biến mà không in key:

```bash
[ -n "$(launchctl getenv ALT_KEY)" ] && echo 'ALT_KEY=set' || echo 'ALT_KEY=missing'
```

Lưu ý: `launchctl setenv` không phải cơ chế lưu secret bền vững qua mọi lần đăng nhập. Với máy dùng lâu dài, ưu tiên macOS Keychain hoặc cơ chế quản lý môi trường doanh nghiệp của máy.

## Cập Nhật Config Không Phá Phần Khác

Nếu file đã có nhiều cấu hình, không thay toàn bộ file bằng một heredoc. Hãy sửa TOML có chủ đích:

- Đảm bảo `model_provider = "alt"`.
- Đảm bảo `model` là model người dùng đã chọn trong danh sách hỗ trợ; mặc định là `GPT-5.6-sol`.
- Chuẩn hóa cách viết của người dùng về `GPT-5.6-sol`, `GPT-5.6-terra` hoặc `GPT-5.6-luna`; không ghi model khác, tên chữ thường hoặc tên có khoảng trắng vào config.
- Đảm bảo `model_reasoning_effort = "medium"`, trừ khi người dùng yêu cầu mức khác.
- Tạo hoặc cập nhật `[model_providers.alt]` với `name`, `base_url`, `env_key` như mẫu.
- Giữ nguyên mọi bảng `[projects."..."]`, MCP và cấu hình khác.

## Xử Lý Lỗi

### `env_key` chứa API key thật

Sai:

```toml
env_key = "sk-..."
```

Đúng:

```toml
env_key = "ALT_KEY"
```

Nếu phát hiện lỗi này, không nhắc lại giá trị key trong output. Hướng dẫn người dùng xoay vòng key nếu key từng bị lưu vào repo, log hoặc chat.

### HTTP `401`

- Không gửi Authorization mà nhận `401`: gateway có thể vẫn hoạt động bình thường.
- Đã gửi key mà vẫn `401`: key thiếu, sai, hết hạn hoặc không có quyền.
- Kiểm tra process Antigravity có thực sự nhận `ALT_KEY` sau khi restart.

### HTTP `404`

Kiểm tra `base_url` có kết thúc bằng `/v1` và URL test là `/v1/models`. Không ghép thành `/v1/v1/models`.

### Không kết nối, timeout hoặc lỗi DNS

Kiểm tra internet, DNS, proxy/firewall, chứng chỉ TLS và khả năng truy cập `https://codex.anhlaptrinh.vn` từ chính máy đó.

### CLI chạy được nhưng extension không chạy

Extension có thể chạy trong môi trường GUI khác terminal. Kiểm tra biến môi trường của desktop session, đúng user home, `CODEX_HOME`, rồi restart toàn bộ Antigravity.

### Extension vẫn dùng provider cũ

- Xác nhận đang sửa user config đúng tài khoản.
- Tìm project-local config có thể ghi đè, nhưng không tự xóa.
- Reload window hoặc thoát hoàn toàn Antigravity rồi mở lại.
- Mở phiên chat Codex mới thay vì dùng phiên cũ.

## Tiêu Chí Hoàn Tất

- `config.toml` và `auth.json` được copy đúng vào thư mục `.codex` của user chạy Antigravity (`%USERPROFILE%\.codex` hoặc `$CODEX_HOME`).
- `auth.json` chứa `OPENAI_API_KEY` hợp lệ, không cần tạo biến môi trường hệ thống khi cấu hình extension.
- Provider trong `config.toml` chỉ tới `https://codex.anhlaptrinh.vn/v1`, model là một trong `GPT-5.6-sol`, `GPT-5.6-terra` hoặc `GPT-5.6-luna`.
- Không có API key thật xuất hiện trong file log hay chat response.
- Antigravity/Codex Extension đã restart và phiên Codex mới hoạt động.

## Mẫu Báo Cáo

```text
Đã cấu hình Codex Extension/Codex CLI dùng ALT Gateway trên <Windows|Linux|macOS>.
File cấu hình: <đường dẫn config.toml>.
Model: <GPT-5.6-sol|GPT-5.6-terra|GPT-5.6-luna>.
API key được lưu qua biến ALT_KEY, không ghi vào config hoặc báo cáo.
Kiểm tra gateway: HTTP <mã>.
Đã yêu cầu restart hoàn toàn Antigravity và mở phiên Codex mới.
```

## Bổ Sung: Telegram OpenClaw - Model Hiển Thị Cũ Hoặc Runtime Codex

Phần này bổ sung cho workflow cũ, không thay thế các quy tắc phía trên.

### Phạm Vi

- Áp dụng khi người dùng đổi model mặc định OpenClaw nhưng hỏi qua Telegram vẫn nhận câu trả lời kiểu `đang chạy 9r/codex` hoặc `/model status` hiển thị model mới nhưng runtime cũ.
- Chỉ sửa đúng VPS/runtime được người dùng chỉ định. Không tự sửa runtime phụ hoặc member VPS.
- Không bật reasoning/thinking mặc định nếu người dùng không yêu cầu. Với workflow này, giữ reasoning ở trạng thái tắt; không tự thêm `reasoningDefault: "on"` hoặc `thinkingDefault`.

### Phân Biệt Model Và Runtime

- `Current`/`Selected` là model được chọn, ví dụ `9r/GPT-5.6-luna`.
- `Active` là runtime thực thi, ví dụ `9r/codex` hoặc runtime `openclaw`.
- Câu trả lời tự nhận model cũ trên Telegram không đủ để kết luận. Phải đối chiếu log request thực tế có dạng `model-fetch ... provider=9r ... model=<model>`.
- Nếu muốn dùng runtime OpenClaw, đặt policy ở provider/model scope, không chỉ đổi `agents.defaults.model.primary`:

```json5
{
  "agents": {
    "defaults": {
      "models": {
        "9r/GPT-5.6-luna": {
          "agentRuntime": { "id": "openclaw" }
        }
      }
    }
  },
  "models": {
    "providers": {
      "9r": {
        "agentRuntime": { "id": "openclaw" }
      }
    }
  }
}
```

Không chép nguyên mẫu trên vào config nếu provider hiện tại không phải `9r`; luôn đọc provider/model đang dùng trước.

### Kiểm Tra Agent Telegram

1. Xác định binding Telegram tới agent nào:

```bash
openclaw_home="${OPENCLAW_HOME:-$HOME/.openclaw}"
openclaw_config="${OPENCLAW_CONFIG_PATH:-$openclaw_home/openclaw.json}"
openclaw_agents_dir="${OPENCLAW_AGENTS_DIR:-$openclaw_home/agents}"
jq '.bindings, .agents.list' "$openclaw_config"
```

2. Kiểm tra model mặc định và allowlist của đúng agent; không in `apiKey`, `auth.json`, cookie hoặc credential:

```bash
openclaw models status --agent <agent-id> --json
agent_models="$openclaw_agents_dir/<agent-id>/agent/models.json"
jq '{providers:(.providers|to_entries|map({id:.key,models:(.value.models|map(.id))}))}' \
  "$agent_models"
```

3. Kiểm tra session Telegram có đang ghim model cũ không. Nếu session entry có `model: "codex"` hoặc model cũ, gửi trong đúng chat:

```text
/model default
```

`/model default` xóa model override của session để session kế thừa model mặc định; `/new` chỉ tạo session mới và không nên được coi là thao tác xóa override model duy nhất.

4. Nếu cần kiểm tra session cụ thể mà không gửi tin thật ra Telegram, dùng session key đúng agent/channel qua CLI; không dùng `--deliver`:

```bash
openclaw agent --agent <agent-id> \
  --session-key 'telegram:direct:<chat-id>' \
  --message '/model default' --json
```

### Validate Và Restart Gateway

- Sau mỗi lần đổi model trong config OpenClaw đang hoạt động, luôn chạy validate rồi restart Gateway; không chỉ dựa vào hot reload.
- Script `set_alt_model.sh` thực hiện restart tự động. Nếu thao tác thủ công, chạy đủ ba lệnh:

```bash
openclaw config validate
openclaw gateway restart
openclaw gateway status
```

- Sau restart, tạo session Telegram mới hoặc gửi `/model default`, rồi kiểm tra lại `/model status` và log request.
- Không báo hoàn tất chỉ dựa trên file JSON. Tiêu chí đạt là log request mới nhất dùng đúng `provider=... model=<model-yêu-cầu>` và Telegram không còn tự nhận model cũ.

### Reasoning Mặc Định

- Không bật reasoning/thinking khi chỉ đổi model, trừ khi người dùng yêu cầu rõ.
- Giữ nguyên `reasoningDefault`/`thinkingDefault` nếu đã có; nếu workflow mới tạo cấu hình và người dùng không yêu cầu reasoning, để mặc định tắt.
- Khi báo cáo, tách riêng model, runtime và reasoning; không gộp `9r/codex` thành tên model nếu log cho thấy đó chỉ là runtime.

### An Toàn Và Bàn Giao

- Backup `openclaw.json`, catalog riêng của agent và session metadata nếu chuẩn bị sửa production.
- Không ghi API key thật vào skill. Khi đọc config để chẩn đoán, chỉ in provider, model, runtime và trạng thái `set/missing` của credential.
- Sau thay đổi quan trọng, ghi backup, lệnh validate, kết quả log request và tình trạng restart vào nhật ký VPS.
