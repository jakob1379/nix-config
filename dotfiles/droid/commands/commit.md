# Custom Slash Command

---

name: /cc description: Generate conventional commit message from staged changes
skill: conventional-commit-generator args:

- name: diff type: string source: git diff --staged

---
