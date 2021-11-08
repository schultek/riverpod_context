
This package brings back the context extensions for [riverpod](https://pub.dev/packages/riverpod) 
that were discontinued in version 1.0.0.

- To read any provider, do `context.read(myProvider)`
- To watch any provider, do `context.watch(myProvider)`

> During the development of riverpod 1.0.0 there was a long discussion on removing the context extensions.
> While being very convenient, there are good reasons why they didn't make it into the final version.

> This is no 'official' riverpod package. It is meant to be used alongside riverpod and offer 
> an alternative to the official `ConsumerWidget` and `ConsumerStatefulWidget`.

## Getting Started

This assumes you already have `flutter_riverpod` (or `hooks_riverpod`) set up.

First, add `riverpod_context` as a dependency.

```shell script
flutter pub add riverpod_context
```

Next, add `InheritedConsumer` underneath the root `ProviderScope`:

```dart
// Before
ProviderScope(
  child: MyApp(),
)
// After
ProviderScope(
  child: InheritedConsumer(
    child: MyApp(),
  ),
)
```

That's all. 

## Context Extensions

`riverpod_context` provides four convenient context extensions to interact with your providers.

### context.read

`context.read` can be used anywhere without any special consideration. 
It naturally supports any providers, provider families as well as the new `.select()` syntax.

```dart
Widget build(BuildContext context) {
  // this won't rebuild based on 'myValue'
  String myValue = context.read(myProvider);
  return Text(myValue);
}
```

### context.watch

`context.watch` watches the provider and triggers a rebuild of the given context when the 
providers state changes. It again supports any providers, provider families as well as the 
new `.select()` syntax.

```dart
Widget build(BuildContext context) {
  // this will rebuild each time 'myValue' changes
  String myValue = context.watch(myProvider);
  return Text(myValue);
}
```

There are a few important considerations to make when using `context.watch`. With those, you
can also safely use any `.autoDispose` providers.

#### 1. Only use inside build()

`context.watch` can only be used inside the `build()` method of a widget. 
Especially interaction callbacks (like `onPressed`) and `StatefulWidget`s `initState`, 
`didChangeDependencies` and other lifecycle handlers are not allowed.
   
#### 2. Be cautious when conditionally watching providers

It is possible to conditionally watch providers. This is the case when `context.watch` may not be
called on every rebuild.

```dart
Widget build(BuildContext context) {
  if (myCondition) {
    return Text(context.watch(myProvider));
  } else {
    return Container();
  }
}
```

In this example, when `myCondition` is `false`, `context.watch` is not called. This leads to an issue
where the dependencies of the provider are not clearly defined.

**It is important to make sure that this does not happen, since it can lead to leaking memory and wrong
behavior!**

> This is also the main reason why this didn't make it into riverpod 1.0.0. There are of 
> course ways to prevent this, but it is in the responsibility of the user to do so and 
> therefore not compile safe.

Preventing this is however pretty simple.

If there exists another `context.watch` on the same context, this issue is resolved. Generally speaking,
it requires at least **one** `context.watch` call on every build to be safe.

If in the example above, the `myCondition` actually comes from another `context.watch` call, you are safe.
```dart
Widget build(BuildContext context) {
  if (context.watch(myConditionProvider)) {
    // don't worry about this being called conditionally, 
    // we already have called context.watch once before
    return Text(context.watch(myProvider));
  } else {
    return Container();
  }
}
```

If there is (under certain conditions) no `context.watch` call, you have to "prime" the context 
for the missing provider. This can be done using a simple `context.prime()`.

In the example above, this can be done either in the `else`, or always at the beginning. It also has
no effect to do it multiple times.
```dart
Widget build(BuildContext context) {
  context.prime(); // option 1: always prime
  if (myCondition) {
    return Text(context.watch(myProvider));
  } else {
    context.prime(); // option 2: prime to account for missing context.watch call
    return Container();
  }
}
```

To recap just remember this:

**Wherever you use `context.watch` conditionally, make sure to either have another unconditional `context.watch` or use `context.prime` on the same context.**

Or in other words:

**You are safe if on each rebuild there always is at least one call to either `context.watch` or `context.prime`.**

### context.refresh

`context.refresh` refreshes any provider.

```dart
Widget build(BuildContext context) {
  return TextButton(
    onPressed: () {
      context.refresh(myProvider);
    },
    child: const Text('Refresh'),
  );
}
```

### context.listen

Listens to a provider without triggering a rebuild.

Coming soon.