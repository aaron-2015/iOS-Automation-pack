# iOS-Automation-pack
一个iOS自动打包并发布到蒲公英的脚本
本文最终实现的是使用脚本自动化对iOS进行打包，并发布到蒲公英上，用户只需要更换自己的一些参数名称，打包环境，证书等就可以轻松实现。
###xcodebuild
本文打包使用的是苹果提供的打包工具：xcodebuild。用兴趣的童鞋可以自己谷歌。
- 打包这里主要提供两种方式：

<pre>
#方式一：需要在包含 name.xcodeproj 的目录下执行 xcodebuild命令，且如果该目录下有多个 projects，那么需要使用 -project 指定需要 build 的项目。
xcodebuild -project $appName.xcodeproj -scheme ${targetName} -configuration $conf -derivedDataPath build -sdk iphoneos ${Profile_UUID} ${args} || exit $?
</pre>

<pre>
#方式二：当 build workspace（例如：使用cocopod的情况下） 时，需要同时指定 -workspace 和 -scheme参数，scheme 参数控制了哪些 targets 会被 build 以及以怎样的方式 build。
xcodebuild -workspace $appName.xcworkspace -scheme ${targetName} -configuration $conf -derivedDataPath build -sdk iphoneos ${Profile_UUID} ${args} || exit $?
</pre>

- 打包后的文件导出为ipa文件，使用 xcrun 命令

<pre>
xcrun -sdk iphoneos PackageApplication -v "$appFile" -o "$ipaPath"
</pre>

#导入证书
可以根据需要，将多套p12证书和PROVISIONING_PROFILE文件直接放到工程文件里面，打包的时候选择一套就可以打出对应的包，不需要再到xcode进行设置了。

![证书.png](http://upload-images.jianshu.io/upload_images/1093584-4f2d925050c6154a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

<pre>
#证书配置
echo "--------证书配置--------"

#选择包类型(根据账号证书类型选择)
bundleId="xxxxx"
bundleName="xxx"

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
</pre>
#dSYM文件保存
在XCODE编译项目之后,会生成一个同名的dSYM文件，一个编译的中转文件,简单说就是debug的symbols包含在这个文件中.他有什么作用? 当release的版本 crash的时候,会有一个日志文件,包含出错的内存地址, 使用symbolicatecrash工具能够把日志和dSYM文件转换成可以阅读的log信息,也就是将内存地址,转换成程序里的函数或变量和所属于的文件名.我们打包后最好也将dSYM文件和ipa文件一起保存至本地，方便其他同事在需要的时候方便解bug

#上传至蒲公英
蒲公英提供了上传API，我们只需填写appid和appkey，将ipa文件上传至蒲公英，即可自动发布。
<pre>
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px Menlo; color: #ffffff}p.p2 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px 'PingFang SC'; color: #4cbf57}p.p3 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px Menlo; color: #e44448}p.p4 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px Menlo; color: #ffffff; min-height: 16.0px}p.p5 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px Menlo; color: #c2349b}p.p6 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px 'PingFang SC'; color: #e44448}span.s1 {font-variant-ligatures: no-common-ligatures; color: #c2349b}span.s2 {font-variant-ligatures: no-common-ligatures}span.s3 {font-variant-ligatures: no-common-ligatures; color: #e44448}span.s4 {font: 14.0px Menlo; font-variant-ligatures: no-common-ligatures}span.s5 {font-variant-ligatures: no-common-ligatures; color: #ffffff}span.s6 {font-variant-ligatures: no-common-ligatures; color: #4cbf57}span.s7 {font: 14.0px 'PingFang SC'; font-variant-ligatures: no-common-ligatures; color: #4cbf57}span.s8 {font: 14.0px 'PingFang SC'; font-variant-ligatures: no-common-ligatures}span.s9 {font: 14.0px Menlo; font-variant-ligatures: no-common-ligatures; color: #ffffff}

if [[ $local != "YES" ]];then
#通过api上传到蒲公英当中
pgyerUKey="xxxxx"  # 这里替换蒲公英ukey
pgyerApiKey="xxxxx" # 这里替换蒲公英apiKey

RESULT=$(curl -F "file=@$ipaPath" -F "uKey=$pgyerUKey" -F "_api_key=$pgyerApiKey" -F "publishRange=2" http://www.pgyer.com/apiv1/app/upload)

echo "完成上传"
echo $RESULT
echo 蒲公英网址 https://www.pgyer.com
else
echo "仅保存至本地，不上传蒲公英"
fi
</pre>

#打包测试

<pre>
aarondeMac-mini:Profile aaron$ bash packg.sh -d

Results at '/Users/aaron/Documents/github/meiboquan/Release/Distribution/meiboquan_201607171956/meiboquan_1.0.1_1_201607171956.ipa' 
dSYMPath -- /Users/aaron/Documents/github/meiboquan/Release/Distribution/meiboquan_201607171956/meiboquan_1.0.1_1_201607171956.app.dSYM
----ipa和dSYM本地文件已生成----
-------开始蒲公英上传--------
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 16.5M  100  2582  100 16.5M     20   131k  0:02:09  0:02:09 --:--:-- 29369
</pre>

![打包后的文件.png](http://upload-images.jianshu.io/upload_images/1093584-c9f823c3a598707c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![蒲公英.png](http://upload-images.jianshu.io/upload_images/1093584-4fcd56cc04211e2d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###github传送门
喜欢的话就给一个星吧，有问题可以一起交流





