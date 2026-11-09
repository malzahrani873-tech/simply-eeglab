// Site-wide settings. Values left empty switch the related feature off.
export const site = {
  eeglabVersion: '2026.1',
  repoUrl: 'https://github.com/malzahrani873-tech/simply-eeglab',
  feedbackFormUrl: '',
  issuesUrl: 'https://github.com/malzahrani873-tech/simply-eeglab/issues',
  discussions: { enabled: false, url: '' },
};

// Production builds show approved lessons only. Branch previews show every status.
export const isProduction =
  process.env.CONTENT_MODE === 'production' ||
  (process.env.CF_PAGES === '1' && process.env.CF_PAGES_BRANCH === 'main');
