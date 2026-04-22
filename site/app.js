// ========== 主题切换 ==========
(function themeToggle() {
  const root = document.documentElement;
  const btn = document.getElementById('themeToggle');
  const icon = btn.querySelector('.theme-icon');

  // 初始化：读 localStorage > 默认 dark（宣讲场景暗色对比更强）
  const saved = localStorage.getItem('pl-theme');
  const initial = saved || 'dark';
  setTheme(initial);

  btn.addEventListener('click', () => {
    const cur = root.getAttribute('data-theme');
    setTheme(cur === 'dark' ? 'light' : 'dark');
  });

  function setTheme(t) {
    root.setAttribute('data-theme', t);
    localStorage.setItem('pl-theme', t);
    // 显示"当前模式"的图标（点击即切换）
    icon.textContent = t === 'dark' ? '☀' : '☾';
    btn.setAttribute('title', t === 'dark' ? '切换到亮色' : '切换到暗色');
  }
})();

// ========== 阶段详情数据 ==========
const STAGE_DATA = {
  SPEC: {
    kicker: 'SPEC · 需求定义',
    title: '把需求变成 StructuredSpec',
    lead: '从 PRD / 截图 / 文字 / 旧代码提取结构化需求，产 spec.md + Open Questions 清单。',
    gates: [
      { id: 'A0', desc: '功能清单完备、Open Questions 已结案' },
    ],
    outputs: ['spec.md', '（可选）design.md', '（可选）specs/**/*.md'],
  },
  PLAN: {
    kicker: 'PLAN · 任务拆解',
    title: '拆成可机器执行的 TaskDAG',
    lead: '设计实施方案（plan.md），切任务依赖图（taskdag.md），定 API Contract（api.md），制定测试矩阵（testmatrix.md）。',
    gates: [
      { id: 'B1', desc: 'TaskDAG 无环；工时合理；API Contract 完备' },
    ],
    outputs: ['plan.md', 'taskdag.md', 'api.md', 'testmatrix.md', 'deps.md'],
  },
  IMPLEMENT: {
    kicker: 'IMPLEMENT · 编码',
    title: '按 TaskDAG 逐任务编码',
    lead: 'AI / 人按拓扑顺序推进任务；变更感知构建（should-build.sh）；每任务完成即可增量验证。',
    gates: [
      { id: 'D', desc: 'checks:[compile_check, lint, test] 全过 · eval:"all_checks.pass"' },
    ],
    outputs: ['源码变更', 'pipeline-output/trace/<change>.events.jsonl（check.run × N）'],
  },
  VERIFY: {
    kicker: 'VERIFY · 静态验证',
    title: '编译 + lint + 单测一次过',
    lead: '由 pl-runner.sh 统一驱动 adapter 注入的 $PL_BUILD_CHECK_CMD / $PL_LINT_CMD / $PL_TEST_CMD。',
    gates: [
      { id: 'D', desc: '同上 · gate.eval 自动派生自 check.run 结果' },
    ],
    outputs: ['gate.eval 事件', '失败时阻塞推进（on_failure: block）'],
  },
  SMOKE: {
    kicker: 'SMOKE · 真启动冒烟',
    title: 'Cold-start + HTTP probe',
    lead: 'v1.1 新增。由 pl-smoke.sh 读 adapter.smoke 配置，真启服务 → 等 ready → HTTP probe → 关停进程树。抓"npm install 通过但启动 500"这类 bug。',
    gates: [
      { id: 'E_smoke', desc: 'checks:[probe:*] 全 pass' },
    ],
    outputs: ['smoke.boot / smoke.ready / check.run × N / smoke.shutdown', 'gate.eval(E_smoke)'],
  },
  OBSERVE: {
    kicker: 'OBSERVE · 漂移观测',
    title: '契约 vs 现实漂移',
    lead: 'piao-contract-drift-compute.sh 对比 adapter 声明契约和宿主实际状态。抓版本不符 / 缺文件 / 坏组合。piao ↔ pl trace 在此合流。',
    gates: [
      { id: 'E', desc: '无 severity=error 漂移（或按业务接受度配置）' },
    ],
    outputs: ['pipeline-output/drift/<change>-contract.yaml', 'piao.contract_drift.detected 事件'],
  },
  ARCHIVE: {
    kicker: 'ARCHIVE · 归档沉淀',
    title: '资产沉淀 6 项检查',
    lead: '把本次 change 的经验归档：更新错误分类、沉淀通用规则到 Rules/Skills、更新架构快照、推广可复用组件。',
    gates: [
      { id: 'F', desc: '所有产物齐全' },
      { id: 'G', desc: '资产沉淀 6 项全过' },
    ],
    outputs: ['更新后的 Rules/Skills', '架构快照更新', 'ARCHITECTURE_SNAPSHOT.md'],
  },
};

// 默认选中 IMPLEMENT（最能体现 v1.1 可执行契约）
let currentStage = 'IMPLEMENT';

function renderStage(stage) {
  const data = STAGE_DATA[stage];
  if (!data) return;
  const detail = document.getElementById('stageDetail');
  detail.innerHTML = `
    <div class="stage-kicker">${data.kicker}</div>
    <h3>${data.title}</h3>
    <p class="stage-lead">${data.lead}</p>
    <div class="stage-grid">
      <div class="stage-block">
        <h4>门禁判据</h4>
        <ul>
          ${data.gates.map(g => `<li><code>${g.id}</code> — ${g.desc}</li>`).join('')}
        </ul>
      </div>
      <div class="stage-block">
        <h4>关键产物 / 事件</h4>
        <ul>
          ${data.outputs.map(o => `<li>${o.includes('<') || o.includes('`') ? o : `<code>${o}</code>`}</li>`).join('')}
        </ul>
      </div>
    </div>
  `;

  // 更新 active 态
  document.querySelectorAll('.step').forEach(el => {
    el.classList.toggle('active', el.dataset.stage === stage);
  });
}

// stepper 点击事件
document.querySelectorAll('.step').forEach(el => {
  el.addEventListener('click', () => {
    currentStage = el.dataset.stage;
    renderStage(currentStage);
  });
});

// 初始渲染
renderStage(currentStage);

// ========== 平滑滚动 active 高亮 ==========
(function navHighlight() {
  const sections = ['problem', 'architecture', 'pipeline', 'contract', 'flywheel', 'start']
    .map(id => document.getElementById(id))
    .filter(Boolean);
  const links = document.querySelectorAll('.nav-links a');

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.id;
        links.forEach(l => {
          const active = l.getAttribute('href') === `#${id}`;
          l.style.color = active ? 'var(--text)' : '';
          l.style.fontWeight = active ? '700' : '';
        });
      }
    });
  }, { rootMargin: '-40% 0px -55% 0px' });

  sections.forEach(s => observer.observe(s));
})();
