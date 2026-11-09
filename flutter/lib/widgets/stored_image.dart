import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/exercises/presentation/cubit/exercises_cubit.dart';

/// An exercise photo from Supabase Storage, shown from its local copy
/// (downloaded on first use). Shows a neutral box while loading or offline.
class StoredImage extends StatelessWidget {
  const StoredImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget box(Widget? child) => Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: child,
    );
    return FutureBuilder<File?>(
      future: context.read<ExercisesCubit>().imageFile(path),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return box(
            snapshot.connectionState == ConnectionState.done
                ? const Icon(Icons.broken_image_outlined)
                : null,
          );
        }
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (_, _, _) =>
              box(const Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
}
