# 自定义名称
function app_rename() {
    if [ "${SECRETS_RENAME}" = "true" ]; then
        debug "✏️ 修改 app_name 为 ${APP_LAUNCH_NAME}"
        
        # 不存在则安装xmlstarlet（仅ubuntu runner生效）
        if ! command -v xmlstarlet &> /dev/null; then
            echo "安装 xmlstarlet..."
            sudo apt update -y && sudo apt install -y xmlstarlet
        fi
        
        local file_list=(
            "${APP_WORKSPACE}/app/src/main/res/values/strings.xml"
            "${APP_WORKSPACE}/app/src/main/res/values-zh/strings.xml"
        )

        for file in "${file_list[@]}"; do
            if [ -f "${file}" ]; then
                echo ">> 正在处理文件：${file}"
                xmlstarlet ed --inplace \
                    -u "//string[@name='app_name']" \
                    -v "${APP_LAUNCH_NAME}" \
                    "${file}" || echo "⚠️ 更新失败: ${file}"
            else
                echo ">> 文件不存在，跳过：${file}"
            fi
        done
    fi
}
app_rename
