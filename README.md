
# 对ruby186源码的修改
- 删除了ext下与win32ole，tk相关的东西。  
- lex.c打补丁，检测 [Clang](http://clang.llvm.org/) 。
- cygwin/GNUmakefile.in，移除-mwindows参数。  

# gcc4在ruby186上的问题
很遗憾，gcc4.8.2（我试过4.4, 4.5, 4.7, 4.8, 4.9）编译的ruby，由于gcc4是posix线程
模型，ruby1.8.x是**green thread**，所以一运行就会报错，如下所示，无法运行。  
```bash
$ ruby -v
ruby 1.8.6p420 [i386-cygwin], with gcc 4.8.2

$ irb
irb(main):001:0> Thread.start { p 123 }
/usr/local/gcc4_ruby186/lib/ruby/1.8/irb.rb:302: [BUG] Segmentation fault
ruby 1.8.6 (2010-09-02) [i386-cygwin]

Aborted (core dumped)
```
所以我们只能编译出一个gcc3.x（gcc3默认是single thread model），
然后用gcc3去编译ruby186。详细内容，请参见 [gcc3.4.6源码编译](gcc3.4.6) 。  

# 配置cygwin依赖库
编译ruby需要的依赖有：  
- gcc3(gcc, gcc-core, gcc-objc, g++)
- make
- libiconv
- zlib && zlib-devel
- openssl && openssl-devel(参见 [openssl098y源码编译]
  (https://github.com/cgywin-fork/openssl098y/blob/master/README.md) )  
将这些都安装好，并且测试可用（比如make -v）。 

# 编译ruby186源码
相关构建步骤参见 [build_it.sh](build_it.sh) 。建议在源码外新建一个目录，方便清理和
切换构建。
#### 构建脚本如下：  
```bash
mkdir tmp
cd tmp
../ruby186/configure --prefix=/usr/local/ruby186 \
  --with-openssl-dir=/usr/local/openssl98y
make
make install
```  
#### 测试：  
```bash
$ ruby -v
ruby 1.8.6p420 [i386-cygwin], with gcc 3.4.6

$ irb
irb(main):001:0> Thread.start { p 123 }
123=> #<Thread:0x7ef8f36c sleep>
irb(main):002:0>
^C
irb(main):002:0> quit
```  

# 安装rubygems
gem 1.4.2，是最后一个支持ruby186的版本，gem 1.5.0 require ruby187。
可以从官方和github下载，我下载以后，修复了安装时校验gem版本的一个BUG。  
#### 安装rubygems：  
```bash
$ ruby setup.rb
RubyGems 1.4.2 installed

﻿=== 1.4.2 / 2011-01-06

Bug fixes:

* Gem::Versions: "1.b1" != "1.b.1", but "1.b1" eql? "1.b.1". Fixes gem indexing.
* Fixed Gem.find_files.
* Removed otherwise unused #find_all_dot_rb. Only 6 days old and hella buggy.


------------------------------------------------------------------------------

RubyGems installed the following executables:
        /usr/local/ruby186/bin/gem
```  
#### 测试：
```bash
$ gem install -p http://127.0.0.1:8087 diff-lcs -v1.1.2
Fetching: diff-lcs-1.1.2.gem (100%)
Successfully installed diff-lcs-1.1.2
1 gem installed
```  
我在自己的rubygems里，关闭了ri和rdoc的：）详细可以参见：  
**[DHH的pull-request](https://github.com/rubygems/rubygems/pull/42)**  

**llvm** 需要给 /usr/include/machine/_default_types.h 打补丁：  
```diff
$ diff -u _default_types.origin_h _default_types.h
--- _default_types.origin_h     2014-03-29 13:49:59.112724000 +0800
+++ _default_types.h    2014-03-29 13:52:42.240054300 +0800
@@ -23,7 +23,7 @@
 extern "C" {
 #endif

-#ifdef __INT8_TYPE__
+#if defined(__INT8_TYPE__) && defined(__UINT8_TYPE__)
 typedef __INT8_TYPE__ __int8_t;
 typedef __UINT8_TYPE__ __uint8_t;
 #define ___int8_t_defined 1
@@ -33,7 +33,7 @@
 #define ___int8_t_defined 1
 #endif

-#ifdef __INT16_TYPE__
+#if defined(__INT16_TYPE__) && defined(__UINT16_TYPE__)
 typedef __INT16_TYPE__ __int16_t;
 typedef __UINT16_TYPE__ __uint16_t;
 #define ___int16_t_defined 1
@@ -51,7 +51,7 @@
 #define ___int16_t_defined 1
 #endif

-#ifdef __INT32_TYPE__
+#if defined(__INT32_TYPE__) && defined(__UINT32_TYPE__)
 typedef __INT32_TYPE__ __int32_t;
 typedef __UINT32_TYPE__ __uint32_t;
 #define ___int32_t_defined 1
@@ -73,7 +73,7 @@
 #define ___int32_t_defined 1
 #endif

-#ifdef __INT64_TYPE__
+#if defined(__INT64_TYPE__) && defined(__UINT64_TYPE__)
 typedef __INT64_TYPE__ __int64_t;
 typedef __UINT64_TYPE__ __uint64_t;
 #define ___int64_t_defined 1
```