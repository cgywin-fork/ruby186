
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
#### gcc编译ruby186
构建脚本如下：  
```bash
mkdir tmp
cd tmp
../ruby186/configure --prefix=/usr/local/ruby186 \
  --with-openssl-dir=/usr/local/openssl98y
make
make install
```  
#### 测试
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
#### 源码安装rubygems
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
#### 测试
```bash
$ gem install -p http://127.0.0.1:8087 diff-lcs -v1.1.2
Fetching: diff-lcs-1.1.2.gem (100%)
Successfully installed diff-lcs-1.1.2
1 gem installed
```  
我在自己的rubygems里，关闭了ri和rdoc的：）详细可以参见：  
**[DHH的pull-request](https://github.com/rubygems/rubygems/pull/42)**  

# clang compile ruby186
gcc是如此蛋疼，所以老娘坚决执行**去GCC**的政策。
#### clang ruby186补丁  
matz对llvm/clang是从ruby1.9.3开始的，ruby1.9.2不支持，只支持mac-gcc，
而且容易出问题。经过老娘的研究，发现cygwin下是可以适配ruby186到clang3.4下的，
主要需要修改：  
- lex.c，增加对clang的适配
- 修改/usr/include/machine下default types的定义适配  

关于**/usr/include/machine/_default_types.h**的内容，详细请参见 
[cygwin-clang-default-type补丁](default_types.diff)  

#### clang编译ruby186
构建脚本如下（参见 [clang build it](clang_build_it.sh)）：  
```bash
mkdir tmp
cd tmp
export CC=/usr/local/llvm34/bin/clang
export CXX=/usr/local/llvm34/bin/clang++
export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments

../ruby186/configure --prefix=/usr/local/llvm_ruby186 \
  --with-openssl-dir=/usr/local/openssl98y
make
make install
```
#### 测试
```bash
$ ruby -v
ruby 1.8.6p420 [i386-cygwin], with LLVM / Clang 3.4

$ irb
irb(main):001:0> Thread.start { p 123 }
123=> #<Thread:0xfff8d388 sleep>
irb(main):002:0>
^C
irb(main):002:0> quit
```
#### 安装rubygems
同前，略过。
#### 测试
```bash
$ gem install -p http://127.0.0.1:8087 cucumber -v0.6.4
Fetching: tins-1.0.1.gem (100%)
Fetching: term-ansicolor-1.3.0.gem (100%)
Fetching: polyglot-0.3.4.gem (100%)
Fetching: treetop-1.5.3.gem (100%)
Fetching: builder-3.2.2.gem (100%)
Fetching: diff-lcs-1.2.5.gem (100%)
Fetching: json_pure-1.8.1.gem (100%)
Fetching: cucumber-0.6.4.gem (100%)

(::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::)

                     (::)   U P G R A D I N G    (::)

Thank you for installing cucumber-0.6.4.
Please be sure to read http://wiki.github.com/aslakhellesoy/cucumber/upgrading
for important information about this release. Happy cuking!

(::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::)

Successfully installed tins-1.0.1
Successfully installed term-ansicolor-1.3.0
Successfully installed polyglot-0.3.4
Successfully installed treetop-1.5.3
Successfully installed builder-3.2.2
Successfully installed diff-lcs-1.2.5
Successfully installed json_pure-1.8.1
Successfully installed cucumber-0.6.4
8 gems installed
```

### 后记
安装完了之后，对比一下llvm ruby186和gcc ruby186的体积和执行速度，嘿嘿……