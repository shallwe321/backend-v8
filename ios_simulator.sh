VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
cd depot_tools
git reset --hard 8d16d4a
cd ..
export DEPOT_TOOLS_UPDATE=0
export PATH=$(pwd)/depot_tools:$PATH
gclient


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['ios']" >> .gclient
cd ~/v8/v8
git checkout refs/tags/$VERSION
gclient sync


# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
python ./tools/dev/v8gen.py x64.release -vv -- '
v8_use_external_startup_data = true
v8_use_snapshot = true
v8_enable_i18n_support = false
is_debug = false
v8_static_library = true
ios_enable_code_signing = false
target_os = "ios"
target_cpu = "x64"
v8_enable_pointer_compression = false
libcxx_abi_unstable = false
'
ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release wee8
strip -S out.gn/x64.release/obj/libwee8.a

node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "ios x64" out.gn/x64.release/snapshot_blob.bin

mkdir -p output/v8/Lib/iOS/x64
cp out.gn/x64.release/obj/libwee8.a output/v8/Lib/iOS/x64/
mkdir -p output/v8/Inc/Blob/iOS/x64
cp SnapshotBlob.h output/v8/Inc/Blob/iOS/x64/
