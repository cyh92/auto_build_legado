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
# web端增加颜色选择器控件
function append_global_component() {
    # 目标ts文件路径，根据你的项目修改
    local TS_FILE="${APP_WORKSPACE}/modules/web/src/components.d.ts"
    local ADD_LINE="ElColorPicker: typeof import('element-plus/es')['ElColorPicker']"

    if [ ! -f "${TS_FILE}" ]; then
        echo "⚠️ 文件不存在：${TS_FILE}"
        return 0
    fi

    # 判断是否已经存在，避免重复插入
    if grep -q "${ADD_LINE}" "${TS_FILE}"; then
        echo "✅ ElColorPicker 已存在，无需追加"
        return 0
    fi

    echo "✏️ 向 GlobalComponents 追加 ElColorPicker"
    # 在 } 前插入内容，匹配 export interface GlobalComponents { ... }
    sed -i "/export interface GlobalComponents {/,/}/{
        /^}/i  ${ADD_LINE}
    }" "${TS_FILE}"
}
# web端插入字体颜色 html 条目
function modify_read_settings_color() {
    local FILE="${APP_WORKSPACE}/modules/web/src/components/ReadSettings.vue"
    if [ ! -f "${FILE}" ]; then
        echo "⚠️ ReadSettings.vue 文件不存在: ${FILE}"
        return 1
    fi

    # ========= 1、插入模板HTML =========
    local HTML_CONTENT='        <li class="font-size">
          <i>字体颜色</i>
          <el-color-picker v-model="fontColor" size="large" :teleported="false" @active-change="onColorChange" popper-class="color-picker-popup" />
        </li>'

    if ! grep -q '<el-color-picker v-model="fontColor"' "${FILE}"; then
        sed -i "/<li class=\"letter-spacing\">/i ${HTML_CONTENT}" "${FILE}"
        echo "✅ 成功插入模板字体颜色DOM"
    else
        echo "ℹ️ DOM内容已存在，跳过插入"
    fi

    # ========= 2、插入script TS代码 =========
    local TS_CODE='//字体颜色
const fontColor = computed({
  get: () => store.config.fontColor,
  set: (value) => (store.config.fontColor = value),
})
const onColorChange = (color: string | null) => {
  if (color) store.config.fontColor = color
}'

    if ! grep -q "const fontColor = computed" "${FILE}"; then
        # 在 //字体大小 相关代码后面插入
        sed -i "/const lessFontSize = () => {/i ${TS_CODE}" "${FILE}"
        echo "✅ 成功插入fontColor TS代码"
    else
        echo "ℹ️ fontColor代码已存在，跳过插入"
    fi
}
app_rename
append_global_component
modify_read_settings_color
