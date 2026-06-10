class SearchResult<T> {
  int? totalCount;
  List<T> items;

  SearchResult({
    this.totalCount,
    List<T>? items,
  }) : items = items ?? [];
}