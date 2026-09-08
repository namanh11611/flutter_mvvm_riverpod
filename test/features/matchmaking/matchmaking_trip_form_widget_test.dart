import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_models.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/user_currency.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/repository/destination_image_service.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/repository/location_search_service.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_shell_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('discovery card swipes through its real image count', (
    tester,
  ) async {
    final trip = MatchmakingTrip(
      id: 'gallery-trip',
      destination: 'Tioman',
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 13)),
      budget: 1000,
      styles: const {'Nature'},
      hostId: 'host',
      hostName: 'Host',
      hostInitials: 'H',
      imageUrl: 'https://example.com/cover.jpg',
      galleryImageUrls: const [
        'https://example.com/photo-1.jpg',
        'https://example.com/photo-2.jpg',
      ],
      gender: 'Any',
      minAge: 18,
      maxAge: 60,
      vacancies: 4,
      description: 'Island trip',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TripCard(
              trip: trip,
              currency: const UserCurrency('USD', r'$'),
              currencyRate: 0.25,
              onDetails: () {},
              onRequest: () {},
              onSave: () {},
              saved: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Verified'), findsNothing);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text(r'$ 250'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-700, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('destination must be selected from suggestions', (tester) async {
    final imageService = _FakeDestinationImageService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveTripFormPage(
            onBack: () {},
            onPublish: (_) {},
            onUploadImage: (_, _, _) async => '',
            onUploadGalleryImage: (_, _, _, _) async => '',
            hostedTrips: const [],
            locationSearchService: _FakeLocationSearchService(),
            destinationImageService: imageService,
          ),
        ),
      ),
    );

    final destination = find.byType(TextFormField).first;
    await tester.enterText(destination, 'Ku');
    await tester.pump();
    await tester.pump();
    expect(find.text('Use "Ku"'), findsNothing);

    await tester.enterText(destination, 'Kuala');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Kuala Lumpur, Malaysia'), findsOneWidget);
    expect(find.text('Kuala Selangor, Selangor, Malaysia'), findsOneWidget);
    expect(imageService.callCount, 0);

    await tester.tap(find.text('Kuala Lumpur, Malaysia'));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(
      tester.widget<TextFormField>(destination).controller!.text,
      'Kuala Lumpur, Malaysia',
    );
    expect(
      tester.widget<TextFormField>(destination).validator!(
        'Kuala Lumpur, Malaysia',
      ),
      isNull,
    );
    expect(imageService.callCount, 1);
    await tester.tap(destination);
    await tester.enterText(destination, 'My custom destination');
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.widget<TextFormField>(destination).controller!.text,
      'My custom destination',
    );
    expect(
      tester.widget<TextFormField>(destination).validator!(
        'My custom destination',
      ),
      'Choose a destination from the suggestions',
    );
  });

  testWidgets('create trip calendar opens when the current date is occupied', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final occupiedTrip = MatchmakingTrip(
      id: 'occupied-trip',
      destination: 'Existing trip',
      startDate: today,
      endDate: today.add(const Duration(days: 2)),
      budget: 100,
      styles: const {'Nature'},
      hostId: 'traveller',
      hostName: 'Traveller',
      hostInitials: 'T',
      imageUrl: '',
      gender: 'Any',
      minAge: 18,
      maxAge: 60,
      vacancies: 2,
      description: '',
      isOwned: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveTripFormPage(
            onBack: () {},
            onPublish: (_) {},
            onUploadImage: (_, _, _) async => '',
            onUploadGalleryImage: (_, _, _, _) async => '',
            hostedTrips: [occupiedTrip],
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsWidgets);

    await tester.tap(fields.at(1));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeLocationSearchService extends LocationSearchService {
  @override
  Future<List<String>> search(String query) async => const [
    'Kuala Lumpur, Malaysia',
    'Kuala Selangor, Selangor, Malaysia',
  ];
}

class _FakeDestinationImageService extends DestinationImageService {
  int callCount = 0;

  @override
  Future<String?> findImageUrl(String destination) async {
    callCount++;
    return 'https://example.com/kuala-lumpur.jpg';
  }
}
