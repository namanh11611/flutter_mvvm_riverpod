part of 'matchmaking_shell_screen.dart';

class RequestPage extends StatefulWidget {
  final MatchmakingTrip trip;
  final VoidCallback onCancel;
  final bool Function(String message) onSend;
  const RequestPage({
    super.key,
    required this.trip,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const Avatar(letter: 'M', size: 72, color: _violet),
          const SizedBox(height: 20),
          const Text('Your request', style: _display),
          const SizedBox(height: 8),
          const VerifiedBadge(),
          const SizedBox(height: 12),
          Text(
            'Joining: ${widget.trip.destination}',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: FieldLabel(
              'MESSAGE TO ${widget.trip.hostName.toUpperCase()}',
            ),
          ),
          const SizedBox(height: 8),
          AppField(
            hint:
                'Introduce yourself and share why this trip feels right for you...',
            lines: 7,
            controller: _controller,
            maxLength: 500,
            onChanged: (_) => setState(() => _error = null),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                '${_controller.text.length} / 500',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
          ],
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Send Request',
            onTap: () {
              if (!widget.onSend(_controller.text)) {
                setState(() => _error = 'Enter a message before sending.');
              }
            },
          ),
          const SizedBox(height: 10),
          OutlineButton(label: 'Cancel', onTap: widget.onCancel),
        ],
      ),
    ),
  );
}

class RequestSentPage extends StatelessWidget {
  final VoidCallback onBack;
  const RequestSentPage({super.key, required this.onBack});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: _lavender,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _violet,
              size: 50,
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Request sent!',
            style: TextStyle(
              fontFamily: 'Georgia',
              color: _ink,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your request has been successfully sent to the trip organizer. They’ll review your profile and get back to you soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 320,
            child: PrimaryButton(label: 'Back to Discover', onTap: onBack),
          ),
        ],
      ),
    ),
  );
}
