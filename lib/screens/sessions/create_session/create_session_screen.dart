import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/common_widgets.dart';
import 'steps/step1_basic_info.dart';
import 'steps/step2_costs.dart';
import 'steps/step4_players_editor.dart';
import 'steps/step5_payments.dart';
import 'steps/step6_summary.dart';
import 'steps/step8_final.dart';

class CreateSessionScreen extends StatefulWidget {
  final Session? template;

  const CreateSessionScreen({super.key, this.template});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  int _step = 0; // 0-5
  late Session _session;
  late double _malePrice;
  late double _femalePrice;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _malePrice = provider.settings.defaultMalePrice;
    _femalePrice = provider.settings.defaultFemalePrice;

    final base = widget.template ??
        Session(
          date: DateTime.now(),
          location: '',
          shuttlePricePerTube: 90,
          tubeCount: 2,
          courtFeePerHour: 0,
          courtCount: 1,
        );
    _session = Session(
      name: base.name,
      date: base.date,
      startTime: base.startTime,
      endTime: base.endTime,
      location: base.location,
      note: base.note,
      shuttleModel: base.shuttleModel,
      shuttlePricePerTube: base.shuttlePricePerTube,
      tubeCount: base.tubeCount,
      courtFeePerHour: base.courtFeePerHour,
      courtCount: base.courtCount,
      extraExpenses: List.from(base.extraExpenses),
      players: List.from(base.players),
    );
  }

  void _next() {
    if (_step < 5) setState(() => _step++);
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _save() async {
    final provider = context.read<AppProvider>();
    _session.isFinalized = true;
    await provider.addSession(_session);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session saved!'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const totalSteps = 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _step == 0 ? () => Navigator.pop(context) : _prev,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StepProgressBar(current: _step + 1, total: totalSteps),
          ),
          Expanded(
            child: _buildStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Step1BasicInfo(session: _session, onNext: _next);
      case 1:
        return Step2Pricing(
          session: _session,
          initialMalePrice: _malePrice,
          initialFemalePrice: _femalePrice,
          onNext: (male, female) {
            setState(() {
              _malePrice = male;
              _femalePrice = female;
            });
            _next();
          },
        );
      case 2:
        return Step4PlayersPaste(
          session: _session,
          malePrice: _malePrice,
          femalePrice: _femalePrice,
          onNext: _next,
        );
      case 3:
        return Step5PlayersEditor(
          session: _session,
          malePrice: _malePrice,
          femalePrice: _femalePrice,
          onNext: _next,
        );
      case 4:
        return Step6QrAndPayments(session: _session, onNext: _next);
      case 5:
        return Step8Final(session: _session, onSave: _save);
      default:
        return const SizedBox();
    }
  }
}
