# The-impact-of-carbon-emission-trading-on-the-digital-economy
探究碳排放权交易对省级数字经济发展水平的影响

**代码包括**

1. **数据加载与预处理**：
   - 读取 `.dta` 格式的数据文件。
   - 对省份名称进行编码 (`encode prov_name, gen(prov)`)。
   - 设置面板数据结构 (`xtset prov year`)。

2. **趋势分析**：
   - 使用 `xtline` 画出 `digeco`（数字经济）变量的趋势，包括单独绘制和 `overlay` 叠加绘制。

3. **双重差分（DID）回归**：
   - 生成政策干预变量 `ppost`（2014 年后的政策影响）。
   - 计算 DID 交互项 `did = Policy * ppost`。
   - 进行基准回归，分别：
     - 仅考虑省级固定效应 (`i.prov`)。
     - 采用双固定效应 (`i.prov i.year`)。
     - 控制变量回归（`lnedu`、`lnfdi`、`lnpgdp`、`lnpwage`、`gov`）。
   - 进行平行趋势检验（`event study`），并绘制 `coefplot` 进行可视化。

4. **安慰剂检验（Placebo Test）**：
   - 重新加载数据，进行 `reghdfe` 回归，吸收固定效应。
   - 进行随机抽取处理变量的 `permute` 过程，并存储模拟结果 (`simulations.dta`)。
   - 计算 `t 值` 和 `p 值`，并绘制核密度图 (`dpplot`)。

5. **中介效应检验（Mediation Analysis）**：
   - 主要考察 `技术创新 (tec)` 和 `产业结构 (str)` 作为中介变量。
   - 采用三步回归 (`reg digeco did ...`, `reg tec did ...`, `reg digeco did tec ...`)。
   - 使用 `sgmediation` 进行 Bootstrap 统计检验。

6. **异质性检验（Heterogeneity Analysis）**：
   - 根据地理区域（东部、中部、西部、南部、北部）进行分组回归，以检验政策影响是否因地区不同而有差异。

7. **稳健性检验（Robustness Check）**：
   - 更换时间窗口进行回归分析，以验证结论的稳健性 (`if year == ...`)。
   - 采用不同的被解释变量 (`minmax_digeco`) 进行回归。

8. **调节效应（Moderation Analysis）**：
   - 生成潜在调节变量 (`lntrans`, `lnpri`, `lnliq`) 及其交互项 (`lntransdid`, `lnpridid`, `liqdid`)。
   - 在 DID 回归模型中加入交互项，观察其影响。

9. **倾向得分匹配+DID（PSM-DID）**：
   - 生成随机变量进行排序，应用 `psmatch2` 进行倾向得分匹配（PSM）。
   - 绘制 `psgraph` 观察匹配前后的倾向得分分布。
   - 使用 `twoway kdensity` 对匹配前后的处理组和控制组倾向得分进行核密度估计。
