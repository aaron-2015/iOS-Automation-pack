#!/bin/bash
#  packg.sh

#获取命令后的参数 例如：ls -a 中的-a
while getopts "dlua:" opt; do
case $opt in
r) release="YES";;
d) dev="YES";;
l) local="YES";;
a) args=$OPTARG;;
?) echo unspport args; exit 1;;
esac
done

#添加宏
args=${args:+GCC_PREPROCESSOR_DEFINITIONS=$args}

#初始文件夹路径
initPath=$(pwd)
echo "初始文件夹路径 -- $initPath"

#返回上一级(根目录)
cd ..
echo "返回上一级 -- $(pwd)"

projectRootPath=$(pwd)
echo "工程根目录 -- $projectRootPath"

#设置参数
if [[ $release == "YES" ]];then
conf=Release
else
conf=Debug
fi

echo $conf

#app名字
appName="meiboquan"

#taget
targetName="meiboquan"

#日期
date=$(date +%Y%m%d%H%M)
echo "开始时间 -- $date"

#ipa文件夹
ipaDir="Release/Distribution/${targetName}_${date}"
echo "ipa文件夹路径 -- $ipaDir"

#XcodeBuild清空设置
xcodebuild clean -configuration $conf

releaseDir="build/Build/Products/${conf}-iphoneos"
echo "releaseDir $releaseDir"

htmlFile="index.html"
PlistBuddy="/usr/libexec/PlistBuddy"

#移除旧目录
rm -rdf ${releaseDir%%/*} #删掉第一个，及其右边的字符串（清除build/中的所有文件夹）
echo "ipaDir $ipaDir"
rm -rdf "$ipaDir"
echo "PWD $(pwd)"

#新建目录
mkdir -p $ipaDir

##更新AppIcon文件夹时间，否则包内图片不会被打包到Bundle
find $initPath/.. -name "AppIcon*" -exec touch {} \;
#
#查找工程plist文件
plistFile=$(find ${appName} -name "Info.plist")
echo "plistFile -- $plistFile"

#获取工程版本号
version=$($PlistBuddy -c "Print :CFBundleShortVersionString" $plistFile)
echo "version -- $version"

#获取工程build号
buildNum=$($PlistBuddy -c "Print :CFBundleVersion" $plistFile)
echo "buildNum -- $buildNum"

#获取工程identifier
identifier=$($PlistBuddy -c "Print :CFBundleIdentifier" $plistFile)
echo "identifier $identifier"

ipa_prefix=${appName}_${version}_${buildNum}_${date}
ipaName=${ipa_prefix}.ipa
echo "IPA文件名 -- $ipaName"

#dSYM文件本地缓存
dSYMBackupPath="${HOME}/Documents/workspace/dSYM/${appName}/${ipa_prefix}"
echo "dSYMBackupPath -- ${dSYMBackupPath}"

mkdir -p $dSYMBackupPath


ipaPath="${projectRootPath}/${ipaDir}/${ipaName}"
appFile="${releaseDir}/${targetName}.app"
dSYMFile=${appFile}.dSYM
remote_dSYMFile=${ipa_prefix}.app.dSYM
dSYMPath="${projectRootPath}/${ipaDir}/${remote_dSYMFile}"
echo "ipaPath -- $ipaPath"
echo "dSYMPath --$dSYMPath"

displayName=$($PlistBuddy -c "print CFBundleDisplayName" $plistFile)
echo "displayName -- $displayName"

#证书配置
echo "--------证书配置--------"

#选择包类型(根据账号证书类型选择)
bundleId="com.beautyisp.meiboquan"
bundleName="美博圈(测试)"

if [[ $dev == "YES" ]];then
#导入证书1(开发证书)
security import ${initPath}/Develop_Ent/meiboquan_iOS_develop_p12.p12 -k ~/Library/Keychains/login.keychain -P "123456" -T /usr/bin/codesign
SIGNING_IDENTITY="iPhone Developer: ya ma (WSHJLKXH4E)"
PROVISIONING_PROFILE="${initPath}/Develop_Ent/meiboquan_iOS_development2016717.mobileprovision"
echo "导入证书1"
else
#导入证书2

echo "导入证书2"
fi

openssl smime -in ${PROVISIONING_PROFILE} -inform der -verify > provisionProfile || exit $?
UUID=$(${PlistBuddy} -c "print UUID" provisionProfile)
echo "UUID -- $UUID"

lib_profile="${HOME}/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"
echo "lib_profile --- $lib_profile"

test ! -e "${lib_profile}" && open ${PROVISIONING_PROFILE}
Profile_UUID="PROVISIONING_PROFILE=${UUID}"
echo "Profile_UUID -- $Profile_UUID"

rm provisionProfile

#
#xcodebuild -project $appName.xcodeproj -scheme ${targetName} -configuration $conf -derivedDataPath build -sdk iphoneos ${Profile_UUID} ${args} || exit $?

xcodebuild -workspace $appName.xcworkspace -scheme ${targetName} -configuration $conf -derivedDataPath build -sdk iphoneos ${Profile_UUID} ${args} || exit $?

xcrun -sdk iphoneos PackageApplication -v "$appFile" -o "$ipaPath"

#dSYM文件保存
echo "dSYMPath -- ${dSYMPath}"

cp -r $appFile ${dSYMBackupPath}/${ipa_prefix}.app
cp -r $dSYMFile ${dSYMBackupPath}/${remote_dSYMFile}
cp -r $dSYMFile ${dSYMPath}

echo "----ipa和dSYM本地文件已生成----"
echo "-------开始蒲公英上传--------"


if [[ $local != "YES" ]];then
#通过api上传到蒲公英当中
pgyerUKey="9d3f71205d4bba59cc3ad76795cb5ccb"  # 这里替换蒲公英ukey
pgyerApiKey="9e66a5551e1547a23d19b7636958c76f" # 这里替换蒲公英apiKey

RESULT=$(curl -F "file=@$ipaPath" -F "uKey=$pgyerUKey" -F "_api_key=$pgyerApiKey" -F "publishRange=2" http://www.pgyer.com/apiv1/app/upload)

echo "完成上传"
echo $RESULT
echo 蒲公英网址 https://www.pgyer.com
else
echo "仅保存至本地，不上传蒲公英"
fi



