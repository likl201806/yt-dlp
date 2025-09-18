# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

yt-dlp 是一个功能丰富的命令行音频/视频下载器，支持数千个网站。它是基于现已停止更新的 youtube-dlc 的 youtube-dl 分支。

## 开发环境设置

### 常用命令

**安装依赖：**
```bash
# 使用 hatch 环境管理
pip install hatch
hatch env create
```

**运行测试：**
```bash
# 运行核心测试
python -m devscripts.run_tests core

# 运行下载测试
python -m devscripts.run_tests download

# 运行特定提取器测试
python -m devscripts.run_tests test_YoutubeDL

# 使用 pytest 运行测试
hatch run test:run

# 使用 pytest 选项
python -m devscripts.run_tests -k "test_name"
```

**代码质量检查：**
```bash
# 代码格式化检查
hatch run hatch-static-analysis:format-check

# 自动修复格式
hatch run hatch-static-analysis:format-fix

# Linting 检查
hatch run hatch-static-analysis:lint-check

# 自动修复 lint 问题
hatch run hatch-static-analysis:lint-fix

# 或者直接使用工具
ruff check --fix .
autopep8 --in-place .
```

**构建项目：**
```bash
# 构建完整项目
make all

# 生成懒加载提取器
make lazy-extractors

# 清理构建文件
make clean

# 生成文档
make doc
```

**运行 yt-dlp：**
```bash
# 开发模式运行
hatch run yt-dlp <url>

# 或者直接运行
python -m yt_dlp <url>
```

## 项目架构

### 核心组件

**主要模块：**
- `yt_dlp/YoutubeDL.py` - 核心下载器类，处理整个下载流程
- `yt_dlp/extractor/` - 网站特定的信息提取器
- `yt_dlp/downloader/` - 各种协议的下载器实现
- `yt_dlp/postprocessor/` - 后处理器（转换、合并等）
- `yt_dlp/networking/` - 网络请求处理
- `yt_dlp/utils/` - 通用工具函数

**提取器架构：**
- `extractor/common.py` - 基础提取器类 `InfoExtractor`
- `extractor/_extractors.py` - 所有提取器的注册列表
- `extractor/lazy_extractors.py` - 自动生成的懒加载提取器（提升启动速度）
- 每个网站都有独立的提取器文件，如 `youtube.py`, `tiktok.py` 等

**下载器类型：**
- HTTP/HTTPS 下载器
- HLS (m3u8) 片段下载器
- DASH (mpd) 下载器
- RTMP 下载器
- 外部下载器集成（aria2c, wget 等）

### 重要设计模式

1. **插件系统** - 支持外部提取器和后处理器插件
2. **懒加载** - 提取器按需加载以提升启动性能
3. **模块化下载** - 不同协议使用专用下载器
4. **统一接口** - 所有提取器继承自 `InfoExtractor`

## 开发规范

### 代码风格
- 使用 ruff 进行 linting，配置在 `pyproject.toml`
- 使用 autopep8 进行代码格式化
- 行长度限制：120 字符
- 使用单引号，文档字符串使用双引号

### 提取器开发规范
- 继承自 `InfoExtractor` 类
- 实现 `_real_extract()` 方法
- 提供完整的测试用例
- 遵循命名约定：`SiteNameIE`
- 处理错误情况和边缘情况

### 测试要求
- 新的提取器必须包含测试用例
- 使用 `@pytest.mark.download` 标记下载测试
- 测试数据放在 `test/testdata/` 目录

### 提交规范
- 使用描述性的提交信息
- 一个提交解决一个问题
- 运行 pre-commit 钩子确保代码质量

## 常见开发任务

### 添加新的网站支持
1. 在 `yt_dlp/extractor/` 创建新的提取器文件
2. 继承 `InfoExtractor` 并实现必要方法
3. 在 `_extractors.py` 中注册新提取器
4. 添加测试用例
5. 运行 `make lazy-extractors` 更新懒加载文件

### 修复现有提取器
1. 找到对应的提取器文件
2. 分析网站变化
3. 更新提取逻辑
4. 确保测试通过
5. 更新测试用例（如需要）

### 性能优化
- 避免不必要的网络请求
- 使用懒加载机制
- 缓存重复计算结果
- 优化正则表达式

## 文件组织

- `devscripts/` - 开发和构建脚本
- `test/` - 测试文件和测试数据
- `bundle/` - 打包相关文件
- `yt_dlp/extractor/youtube/` - YouTube 专用提取器（包含 POT 框架）
- `yt_dlp/compat/` - 兼容性层
- `yt_dlp/dependencies/` - 可选依赖处理

## 注意事项

- 始终在最新版本基础上开发
- 测试修改不会破坏现有功能
- 遵循项目的编码约定
- 考虑向后兼容性
- 注意性能影响，特别是启动时间