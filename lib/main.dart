import 'dart:async';
import 'dart:typed_data';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tweet_storm/amplifyconfiguration.dart';
import 'package:flutter_tweet_storm/models/ModelProvider.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:timeago/timeago.dart' as timeago;

final logger = AmplifyLogger().createChild('TweetStormApp');
const amplifyOrange = Color(0xFFFF9900);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Amplify.addPlugins([
    AmplifyAuthCognito(),
    AmplifyAPI(
      modelProvider: ModelProvider.instance,
    ),
    AmplifyStorageS3(),
  ]);
  await Amplify.configure(amplifyconfig);
  runApp(const TweetStormApp());
}

class TweetStormApp extends StatelessWidget {
  const TweetStormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        title: 'Tweet Storm',
        theme: ThemeData(
          fontFamily: 'Amazon Ember',
          colorScheme: ColorScheme.fromSeed(
            seedColor: amplifyOrange,
            primary: amplifyOrange,
          ),
          tabBarTheme: const TabBarTheme(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: amplifyOrange),
            ),
            labelColor: amplifyOrange,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        home: const FeedScreen(),
        debugShowCheckedModeBanner: false,
        builder: Authenticator.builder(),
      ),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static final _faker = Faker(seed: 2);
  late final _tweetController = TextEditingController();
  late final _filterStream = StreamController<String>.broadcast(sync: true);
  late final _filterController = TextEditingController();
  final _tweets = <Tweet>[];
  Uint8List? _attachedImage;
  StreamSubscription<Tweet>? _activeSubscription;
  void Function()? _cancelStorm;

  @override
  void initState() {
    super.initState();
    _setUpSubscription();
    _filterController.addListener(
      () => _filterStream.add(_filterController.text),
    );
    _filterStream.stream
        .debounce(const Duration(milliseconds: 500))
        .distinct()
        .listen((event) => _setUpSubscription(filter: event));
  }

  @override
  void dispose() {
    _filterStream.close();
    _tweetController.dispose();
    _filterController.dispose();
    _activeSubscription?.cancel();
    super.dispose();
  }

  void _setUpSubscription({String? filter}) {
    _activeSubscription?.cancel();
    final tweetStorm = Amplify.API
        .subscribe(
      onEstablished: () => logger.info('Subscription established'),
      GraphQLRequest<Tweet>(
        document: r'''
        subscription OnCreateTweet($filter: ModelSubscriptionTweetFilterInput) {
          onCreateTweet(filter: $filter) {
            id
            author
            content
            imageKey
            createdAt
            updatedAt
          }
        }
        ''',
        decodePath: 'onCreateTweet',
        modelType: Tweet.classType,
        authorizationMode: APIAuthorizationType.iam,
        variables: {
          if (filter != null)
            'filter': {
              'content': {
                'contains': filter.toLowerCase(),
              },
            },
        },
      ),
    )
        .map((event) {
      if (event.hasErrors) {
        throw Exception(event.errors);
      }
      return event.data;
    }).whereType<Tweet>();

    _activeSubscription = tweetStorm.listen(
      (tweet) {
        setState(() {
          _tweets.insert(0, tweet);
        });
      },
      onError: (Object e) {
        logger.error('Error in subscription', e);
        _showBanner(
          e.toString(),
          type: BannerType.error,
        );
      },
      onDone: () => logger.info('Subscription done'),
    );
  }

  void _showBanner(String content, {required BannerType type}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(type.icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(content),
            ],
          ),
          backgroundColor: type.color,
        ),
      );
  }

  Future<void> _attachImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        withReadStream: false,
        allowMultiple: false,
      );

      setState(() {
        _attachedImage = result?.files.single.bytes;
      });
    } on Exception catch (e) {
      logger.error('Error attaching image', e);
      _showBanner(e.toString(), type: BannerType.error);
    }
  }

  Future<void> _tweet({
    String? content,
    Uint8List? imageBytes,
  }) async {
    try {
      String? imageKey;
      imageBytes ??= _attachedImage;
      if (imageBytes != null) {
        final session = await Amplify.Auth.fetchAuthSession(
          options: const CognitoSessionOptions(getAWSCredentials: true),
        ) as CognitoAuthSession;
        final identityId = session.identityId!;
        imageKey = '$identityId/${uuid()}';
        await Amplify.Storage.uploadData(
          data: HttpPayload.bytes(imageBytes),
          key: imageKey,
        ).result;
      }
      final resp = await Amplify.API
          .mutate(
            request: GraphQLRequest<Tweet>(
              document: r'''
                mutation CreateTweet($content: String!, $imageKey: String) {
                  createTweet(input: {
                    content: $content
                    imageKey: $imageKey
                  }) {
                    id
                    author
                    content
                    imageKey
                    createdAt
                    updatedAt
                  }
                }
              ''',
              variables: {
                'content': content ?? _tweetController.text,
                'imageKey': imageKey,
              },
              decodePath: 'createTweet',
              modelType: Tweet.classType,
            ),
          )
          .response;
      if (resp.hasErrors) {
        logger.error('Error creating tweet', resp.errors!.first);
        return _showBanner(
          resp.errors!.first.toString(),
          type: BannerType.error,
        );
      }
      setState(() {
        _attachedImage = null;
        _tweetController.clear();
      });
      _showBanner('Successfully posted tweet!', type: BannerType.success);
    } on Exception catch (e) {
      logger.error('Error creating tweet', e);
      _showBanner(e.toString(), type: BannerType.error);
    }
  }

  Future<void> _tweetStorm() async {
    final cancelCompleter = Completer<void>();
    unawaited(
      cancelCompleter.future.then((_) {
        setState(() => _cancelStorm = null);
      }),
    );
    try {
      setState(
        () => _cancelStorm = () {
          if (!cancelCompleter.isCompleted) cancelCompleter.complete();
        },
      );
      while (!cancelCompleter.isCompleted) {
        final dish = _faker.food.dish().toLowerCase();
        logger.info('Generated dish: $dish');
        final image = _faker.image.image(
          width: 300,
          height: 300,
          keywords: dish.split(' ').toList(),
          random: false,
        );
        logger.info('Generated image: $image');
        final imageResp =
            await AWSHttpRequest.get(Uri.parse(image)).send().response;
        final imageBytes = Uint8List.fromList(await imageResp.bodyBytes);
        await _tweet(
          content: dish,
          imageBytes: imageBytes,
        );
      }
    } on Exception catch (e) {
      logger.error('Error storming', e);
    } finally {
      if (!cancelCompleter.isCompleted) {
        cancelCompleter.complete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, kToolbarHeight),
        child: SafeArea(
          child: SizedBox(
            height: kToolbarHeight,
            child: Material(
              elevation: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tweetController,
                          decoration: InputDecoration(
                            hintText: 'Content',
                            suffix: _attachedImage == null
                                ? null
                                : Image.memory(
                                    _attachedImage!,
                                    cacheWidth: 30,
                                    cacheHeight: 30,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _attachImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Attach Image'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _tweet,
                        icon: const Icon(Icons.send),
                        label: const Text('Tweet'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ListView.separated(
                itemCount: _tweets.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final tweet = _tweets[index];
                  final imageKey = tweet.imageKey;
                  final time =
                      timeago.format(tweet.createdAt!.getDateTimeInUtc());
                  if (imageKey == null) {
                    return ListTile(
                      title: Text(tweet.content),
                      subtitle:
                          tweet.author == null ? null : Text(tweet.author!),
                      trailing: Text(time),
                    );
                  }
                  return ExpansionTile(
                    title: Text(tweet.content),
                    subtitle: tweet.author == null ? null : Text(tweet.author!),
                    trailing: Text(time),
                    childrenPadding: const EdgeInsets.all(8),
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: FutureBuilder(
                          future: Amplify.Storage.getUrl(key: imageKey).result,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final imageUrl = snapshot.data!.url;
                            return CachedNetworkImage(
                              imageUrl: imageUrl.toString(),
                              cacheKey: imageKey,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                width: 200,
                height: 50,
                bottom: 10,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _filterController,
                      decoration: const InputDecoration(
                        hintText: 'Subscription Filter',
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: _cancelStorm == null
          ? FloatingActionButton(
              onPressed: _tweetStorm,
              tooltip: 'Tweet Storm',
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.storm),
            )
          : FloatingActionButton(
              onPressed: _cancelStorm,
              tooltip: 'Cancel Storm',
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

enum BannerType {
  error(color: Colors.red, icon: Icons.error),
  success(color: Colors.green, icon: Icons.check);

  const BannerType({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;
}
