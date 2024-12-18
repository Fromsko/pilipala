import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../utils/storage.dart';
import '../../utils/utils.dart';

class ListSheet {
  ListSheet({
    required this.episodes,
    this.bvid,
    this.aid,
    required this.currentCid,
    required this.changeFucCall,
    required this.context,
  });

  final dynamic episodes;
  final String? bvid;
  final int? aid;
  final int currentCid;
  final Function changeFucCall;
  final BuildContext context;

  late PersistentBottomSheetController bottomSheetController;

  void buildShowBottomSheet() {
    bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) => ListSheetContent(
              episodes: episodes,
              bvid: bvid,
              aid: aid,
              currentCid: currentCid,
              changeFucCall: changeFucCall,
              onClose: bottomSheetController.close,
            ));
  }
}

class ListSheetContent extends StatefulWidget {
  const ListSheetContent({
    super.key,
    required this.episodes,
    this.bvid,
    this.aid,
    required this.currentCid,
    required this.changeFucCall,
    required this.onClose,
  });

  final dynamic episodes;
  final String? bvid;
  final int? aid;
  final int currentCid;
  final Function changeFucCall;
  final Function() onClose;

  @override
  State<ListSheetContent> createState() => _ListSheetContentState();
}

class _ListSheetContentState extends State<ListSheetContent> {
  final ItemScrollController itemScrollController = ItemScrollController();
  late final int currentIndex =
      widget.episodes!.indexWhere((dynamic e) => e.cid == widget.currentCid) ??
          0;
  bool reverse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      itemScrollController.jumpTo(index: currentIndex);
    });
  }

  Widget buildEpisodeListItem(
    dynamic episode,
    int index,
    bool isCurrentIndex,
  ) {
    Color primary = Theme.of(context).colorScheme.primary;
    late String title;
    if (episode.runtimeType.toString() == "EpisodeItem") {
      if (episode.longTitle != null && episode.longTitle != "") {
        title = "第${(episode.title ?? '${index + 1}')}话  ${episode.longTitle!}";
      } else {
        title = episode.title!;
      }
    } else if (episode.runtimeType.toString() == "PageItem") {
      title = episode.pagePart!;
    } else if (episode.runtimeType.toString() == "Part") {
      title = episode.pagePart!;
      // print("未知类型：${episode.runtimeType}");
    }
    return ListTile(
      onTap: () {
        if (episode.badge != null && episode.badge == "会员") {
          dynamic userInfo = GStorage.userInfo.get('userInfoCache');
          int vipStatus = 0;
          if (userInfo != null) {
            vipStatus = userInfo.vipStatus;
          }
          if (vipStatus != 1) {
            SmartDialog.showToast('需要大会员');
            return;
          }
        }
        SmartDialog.showToast('切换到：$title');
        widget.onClose();
        if (episode.runtimeType.toString() == "EpisodeItem") {
          widget.changeFucCall(episode.bvid, episode.cid, episode.aid);
        } else {
          widget.changeFucCall(widget.bvid!, episode.cid, widget.aid!);
        }
      },
      dense: false,
      leading: isCurrentIndex
          ? Image.asset(
              'assets/images/live.png',
              color: primary,
              height: 12,
              semanticLabel: "正在播放：",
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isCurrentIndex
              ? primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (episode.badge != null) ...[
            if (episode.badge == '会员')
              Image.asset(
                'assets/images/big-vip.png',
                height: 20,
                semanticLabel: "大会员",
              ),
            if (episode.badge != '会员') Text(episode.badge),
            const SizedBox(width: 10),
          ],
          if (!(episode.runtimeType.toString() == 'EpisodeItem' &&
              (episode.longTitle != null && episode.longTitle != '')))
            Text('${index + 1}/${widget.episodes!.length}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Utils.getSheetHeight(context),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 45,
            padding: const EdgeInsets.only(left: 14, right: 14),
            child: Row(
              children: [
                Text(
                  '合集（${widget.episodes!.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: '跳至顶部',
                  icon: const Icon(Icons.vertical_align_top),
                  onPressed: () {
                    itemScrollController.scrollTo(
                      index: !reverse ? 0 : widget.episodes!.length - 1,
                      duration: const Duration(milliseconds: 200),
                    );
                  },
                ),
                IconButton(
                  tooltip: '跳至底部',
                  icon: const Icon(Icons.vertical_align_bottom),
                  onPressed: () {
                    itemScrollController.scrollTo(
                      index: !reverse ? widget.episodes!.length - 1 : 0,
                      duration: const Duration(milliseconds: 200),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: '反序',
                  icon: Icon(!reverse
                      ? MdiIcons.sortAscending
                      : MdiIcons.sortDescending),
                  onPressed: () {
                    setState(() {
                      reverse = !reverse;
                    });
                  },
                ),
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          Expanded(
            child: Material(
              child: ScrollablePositionedList.separated(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20),
                reverse: reverse,
                itemCount: widget.episodes!.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildEpisodeListItem(
                    widget.episodes![index],
                    index,
                    currentIndex == index,
                  );
                },
                itemScrollController: itemScrollController,
                separatorBuilder: (_, index) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
