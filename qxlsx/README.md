# QXlsx（源码内嵌）

本目录是 QXlsx 库源码的副本，已并入本仓库并随主工程一起编译，不再通过
`add_subdirectory` 引入外部仓库。

- 上游项目：https://github.com/QtExcel/QXlsx
- 版本：1.5.1
- 许可证：MIT，见 [LICENSE](LICENSE)
- 保留内容：仅 `header/` 与 `source/` 两个目录，即构建所需的全部库代码
- 未改动上游源码；示例、测试、文档、安装脚本与 CI 配置未纳入

升级方式：从上游对应版本中替换 `header/`、`source/` 两个目录的内容，
并在 `CMakeLists.txt` 中确认源文件列表（使用通配收集，无需逐个维护）。
