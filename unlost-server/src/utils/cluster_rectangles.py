def is_overlapping(rect1, rect2):
    xmin1, ymin1, xmax1, ymax1 = rect1
    xmin2, ymin2, xmax2, ymax2 = rect2
    return (xmin1 < xmax2 and xmin2 < xmax1) and (ymin1 < ymax2 and ymin2 < ymax1)


def is_similar(rect1, rect2, threshold):
    xmin1, ymin1, xmax1, ymax1 = rect1
    xmin2, ymin2, xmax2, ymax2 = rect2

    dy1 = ymax1 - ymin1
    dy2 = ymax2 - ymin2
    diff = abs(dy1 - dy2) / max(dy1, dy2)
    return diff < threshold


def expand_rectangle(rect, threshold):
    dx = (rect[2] - rect[0]) * threshold
    dy = (rect[3] - rect[1]) * threshold
    d = min(dx, dy)
    return [rect[0] - d, rect[1] - d, rect[2] + d, rect[3] + d]


def cluster_intersecting_rectangles(rects, threshold):
    graph = {}
    rectangles = [expand_rectangle(rect, threshold) for rect in rects]

    for i in range(len(rectangles)):
        graph[i] = set()

    # Create the graph with overlapping rectangles
    for i in range(len(rectangles)):
        for j in range(i + 1, len(rectangles)):
            if is_overlapping(rectangles[i], rectangles[j]) and is_similar(
                rectangles[i], rectangles[j], threshold * 0.75
            ):
                graph[i].add(j)
                graph[j].add(i)

    clusters = []
    visited = set()

    # Find connected components using Depth-First Search
    def dfs(node, cluster):
        visited.add(node)
        cluster.append(node)
        for neighbor in graph[node]:
            if neighbor not in visited:
                dfs(neighbor, cluster)

    for node in range(len(rectangles)):
        if node not in visited:
            cluster = []
            dfs(node, cluster)
            clusters.append([rects[node] for node in cluster])

    return clusters
