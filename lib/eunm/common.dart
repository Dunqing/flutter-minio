enum MaxDownloadCount { One, Three, Five }

int getMaxDownloadValue(MaxDownloadCount value) {
  switch (value) {
    case MaxDownloadCount.One:
      return 1;
    case MaxDownloadCount.Three:
      return 3;
    case MaxDownloadCount.Five:
      return 5;
    default:
      return 3;
  }
}
