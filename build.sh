cur_dir=$(pwd)

xcodebuild clean -workspace MiniAppBuilder.xcworkspace -scheme MiniAppBuilder -derivedDataPath ./build/MiniAppBuilder
if [ $? -ne 0 ]; then
    echo -e "\033[31m execute failed \033[0m"
    exit 1
fi

echo "\033[0;32mStart: build MiniAppBuilder \033[0m"
xcodebuild -workspace MiniAppBuilder.xcworkspace -scheme MiniAppBuilder -derivedDataPath ./build/MiniAppBuilder -configuration Release ONLY_ACTIVE_ARCH=NO
if [ $? -ne 0 ]; then
    echo -e "\033[31m execute failed \033[0m"
    exit 1
fi
