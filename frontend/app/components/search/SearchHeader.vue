<template>
  <div class="site-title">
    <h1>🎬 Movie Search <span class="badge">Elasticsearch POC</span></h1>
  </div>
</template>

<style scoped>
.site-title {
  margin-bottom: 16px;
}

h1 {
  margin: 0;
  font-size: 22px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--text);
}

.badge {
  font-size: 11px;
  font-weight: 500;
  background: var(--accent);
  color: white;
  padding: 3px 8px;
  border-radius: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
</style>
