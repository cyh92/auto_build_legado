#!/bin/sh
# 模块化自定义脚本：用于构建 阅读.A 共存版 APK

source $GITHUB_WORKSPACE/action_util.sh

# 签名配置
function app_sign() {
    debug "🔏 注入签名配置"
    cp $GITHUB_WORKSPACE/.github/legado/legado.jks $APP_WORKSPACE/app/legado.jks
    sed '$r '"$GITHUB_WORKSPACE/.github/legado/legado.sign"'' $APP_WORKSPACE/gradle.properties -i
}

# 清除 18+ 限制
function app_clear_18plus() {
    debug "🧼 清除 18PlusList.txt"
    echo "" > $APP_WORKSPACE/app/src/main/assets/18PlusList.txt
}

# 修改名称为 阅读.A
function app_rename() {
    if [ "$SECRETS_RENAME" = "true" ]; then
        debug "✏️ 修改 app_name 为 $APP_LAUNCH_NAME"
        for file in "$APP_WORKSPACE/app/src/main/res/values"/strings.xml "$APP_WORKSPACE/app/src/main/res/values-zh"/strings.xml; do
            if [ -f "$file" ]; then
                sed -i "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">$APP_LAUNCH_NAME</string>|" "$file" || true
            fi
        done
    fi
}

# 共存包名配置
function app_enable_coexist() {
    debug "📦 强制设置 applicationId 和 applicationIdSuffix"

    # 删除旧配置
    sed -i '/applicationIdSuffix/d' $APP_WORKSPACE/app/build.gradle
    sed -i '/applicationId "/d' $APP_WORKSPACE/app/build.gradle

    # 插入 applicationId 和 Suffix
    sed -i "/defaultConfig {/a\        applicationId \"io.legado.app\"\n        applicationIdSuffix \".$APP_SUFFIX\"" \
        $APP_WORKSPACE/app/build.gradle
}

# Room schema 配置
function app_patch_room_assets() {
    debug "📚 添加 Room schema 到 assets"
    sed -i "/sourceSets {/,/main {/s|main {|main {\n            assets.srcDirs += files(\"\\$projectDir/schemas\")|" "$APP_WORKSPACE/app/build.gradle"
}

# 缩小 APK 大小
function app_minify() {
    if [ "$SECRETS_MINIFY" = "true" ]; then
        debug "📦 启用 minify 和 shrinkResources"
        sed -e '/minifyEnabled/i\
            shrinkResources true' \
            -e 's/minifyEnabled false/minifyEnabled true/' \
            $APP_WORKSPACE/app/build.gradle -i
    fi
}

# Firebase/Google 插件
function app_disable_plugins() {
    debug "🚫 删除 google-services 等插件"

    # 删除 app/build.gradle 中相关行
    sed -i -e "/com.google.gms.google-services/d" \
           -e "/com.google.firebase/d" \
           -e "/io.fabric/d" \
           -e "/apply plugin: 'com.google.gms.google-services'/d" \
           -e "/apply plugin: 'com.google.firebase.crashlytics'/d" \
           -e "/id 'com.google.gms.google-services'/d" \
           -e "/id 'com.google.firebase.crashlytics'/d" \
           $APP_WORKSPACE/app/build.gradle || true

    # 删除根级 build.gradle 的 classpath
    sed -i -e "/classpath 'com.google.gms:google-services/d" \
           -e "/classpath 'com.google.firebase:firebase-crashlytics-gradle/d" \
           $APP_WORKSPACE/build.gradle || true

    # 删除 gradle.properties 中关联配置
    sed -i '/firebaseCrashlyticsCollectionEnabled/d' $APP_WORKSPACE/gradle.properties || true
    sed -i '/googleServices.disableVersionCheck/d' $APP_WORKSPACE/gradle.properties || true

    # 删除 google-services.json
    rm -f $APP_WORKSPACE/app/google-services.json || true

    sed -i "/androidx.appcompat/a\    implementation 'androidx.documentfile:documentfile:1.0.1'" \
        $APP_WORKSPACE/app/build.gradle || true

    # patch 禁用 Gradle 进程中的构建任务
    cat <<'EOF' >> $APP_WORKSPACE/app/build.gradle
// 🔻 patch: 禁用 google-services 相关任务
gradle.taskGraph.whenReady {
    tasks.findAll { it.name ==~ /process.*GoogleServices/ }.each {
        it.enabled = false
        println "🚫 Firebase GoogleServices task 被禁用：\${it.name}"
    }
}
EOF
}

# 删除多余资源
function app_remove_unused() {
    debug "🗑️ 删除无用资源 bg/"
    rm -rf $APP_WORKSPACE/app/src/main/assets/bg
}

# === 调用所有步骤 ===
app_sign
app_clear_18plus
# app_rename
# app_enable_coexist
app_patch_room_assets
app_minify
app_disable_plugins
app_remove_unused
