import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;

  const AsyncValueWidget({
    super.key, 
    required this.value, 
    required this.builder, 
    this.loadingWidget
    });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loadingWidget?? const Center(child: CircularProgressIndicator(),),
      error: (e,_)=>Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,size: 48,color:AppColors.danger,),
            const SizedBox(height: 8,),
            Text(e.toString(),textAlign: TextAlign.center,)
          ],
        ),
      ),
      data: builder
    );
  }
}
