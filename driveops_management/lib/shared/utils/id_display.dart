String shortId(String id, {int take = 4, bool fromEnd = false}) {
  if (id.length <= take) return id;
  return fromEnd ? id.substring(id.length - take) : id.substring(0, take);
}
