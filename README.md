# azure-personal-reports

[![Scheduled Reporting Workflow](https://github.com/jpfulton/azure-personal-reports/actions/workflows/reporting-workflow.yml/badge.svg)](https://github.com/jpfulton/azure-personal-reports/actions/workflows/reporting-workflow.yml)
![License](https://img.shields.io/badge/License-MIT-blue)
![Visitors](https://visitor-badge.laobi.icu/badge?page_id=jpfulton.azure-personal-reports)

This repository hosts the outputs of an Azure audit utility and an Azure cost
reporting utility on a personal Azure subscription. The utilities are run in a
scheduled Github Actions workflow and render markdown files that are then committed
back to this repository. The workflows and supporting scripts are designed as an
example of how to harness the utilities for reporting against any Azure subscription.

- [azure-personal-reports](https://github.com/jpfulton/azure-personal-reports)
- [azure-cost-cli](https://github.com/mivano/azure-cost-cli)

## Reports

- [Audit Reports Summary](./audit-reports/README.md)
- [Cost Reports Summary](./cost-reports/README.md)
