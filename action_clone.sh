#!/bin/sh
#本脚本用来clone远端仓库
source $GITHUB_WORKSPACE/action_util.sh
echo $APP_BRANCHME
echo $APP_GIT_URL
echo $APP_WORKSPACE
#建立工作目录
function init_workspace()
{
    git clone -b $APP_BRANCHME $APP_GIT_URL $APP_WORKSPACE
    cd $APP_WORKSPACE
    LatestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
   
    set_env APP_UPLOAD_NAME $APP_NAME-$LatestTag
    # [[ "$APP_NAME" = "legado" ]] && \
    set_env APP_TAG    $(echo $LatestTag|grep -o '3\.[0-9]\{2\}\.[0-9]\{6\}')
    debug "$APP_NAME latest tag is $LatestTag"
}
init_workspace;

