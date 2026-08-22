import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ShelemYarApp());

enum GameType { shelem165, shelem200 }

enum ContractStatus { success, failure, yasa }

class RuleSet {
  final GameType type;
  final int totalPoints;
  final int minContract;
  final int contractStep;
  final int yasaThreshold;
  final int redJoker;
  final int blackJoker;
  const RuleSet({required this.type, required this.totalPoints, required this.minContract, required this.contractStep, required this.yasaThreshold, this.redJoker = 0, this.blackJoker = 0});
  String get id => type == GameType.shelem165 ? 'standard_165' : 'standard_200';
  String get title => type == GameType.shelem165 ? 'شلم ۱۶۵ امتیازی' : 'شلم ۲۰۰ امتیازی با جوکر';
  List<int> get validContracts => List.generate(((totalPoints - minContract) ~/ contractStep) + 1, (i) => minContract + i * contractStep);
  Map<String, dynamic> toJson() => {'type': type.name, 'totalPoints': totalPoints, 'minContract': minContract, 'contractStep': contractStep, 'yasaThreshold': yasaThreshold, 'redJoker': redJoker, 'blackJoker': blackJoker};
  static RuleSet fromType(GameType t) => t == GameType.shelem165
      ? const RuleSet(type: GameType.shelem165, totalPoints: 165, minContract: 100, contractStep: 5, yasaThreshold: 85)
      : const RuleSet(type: GameType.shelem200, totalPoints: 200, minContract: 100, contractStep: 5, yasaThreshold: 100, redJoker: 20, blackJoker: 15);
}

class RoundInput {
  final int contract;
  final int declarerRaw;
  final int opponentRaw;
  final String declarer;
  const RoundInput({required this.contract, required this.declarerRaw, required this.opponentRaw, required this.declarer});
}

class RoundResult {
  final int declarerRaw;
  final int opponentRaw;
  final int declarerChange;
  final int opponentChange;
  final ContractStatus status;
  final String message;
  const RoundResult({required this.declarerRaw, required this.opponentRaw, required this.declarerChange, required this.opponentChange, required this.status, required this.message});
}

class ScoringEngine {
  static RoundResult calculate(RuleSet rules, RoundInput input) {
    if (!rules.validContracts.contains(input.contract)) throw ArgumentError('مقدار تعهد معتبر نیست.');
    if (input.declarerRaw < 0 || input.opponentRaw < 0) throw ArgumentError('امتیاز خام نمی‌تواند منفی باشد.');
    if (input.declarerRaw + input.opponentRaw != rules.totalPoints) throw ArgumentError('مجموع امتیازهای خام باید ${rules.totalPoints} باشد.');
    if (input.declarerRaw < rules.yasaThreshold) {
      return RoundResult(declarerRaw: input.declarerRaw, opponentRaw: input.opponentRaw, declarerChange: -input.contract, opponentChange: rules.totalPoints, status: ContractStatus.yasa, message: 'یاسا: تیم حاکم به حداقل امتیاز لازم نرسید.');
    }
    if (input.declarerRaw >= input.contract) {
      return RoundResult(declarerRaw: input.declarerRaw, opponentRaw: input.opponentRaw, declarerChange: input.contract, opponentChange: input.opponentRaw, status: ContractStatus.success, message: 'تعهد با موفقیت انجام شد.');
    }
    return RoundResult(declarerRaw: input.declarerRaw, opponentRaw: input.opponentRaw, declarerChange: -input.contract, opponentChange: input.opponentRaw, status: ContractStatus.failure, message: 'تعهد انجام نشد.');
  }
}

class GameRound {
  final String id;
  final RoundInput input;
  final RoundResult result;
  GameRound(this.id, this.input, this.result);
  Map<String,dynamic> toJson() => {'id': id, 'contract': input.contract, 'declarerRaw': input.declarerRaw, 'opponentRaw': input.opponentRaw, 'declarer': input.declarer};
}

class GameState {
  RuleSet rules;
  List<String> teamA;
  List<String> teamB;
  int target;
  final List<GameRound> rounds;
  GameState({required this.rules, required this.teamA, required this.teamB, required this.target, List<GameRound>? rounds}) : rounds = rounds ?? [];
  int get scoreA => rounds.fold(0, (s,r) => s + (r.input.declarer == 'A' ? r.result.declarerChange : r.result.opponentChange));
  int get scoreB => rounds.fold(0, (s,r) => s + (r.input.declarer == 'B' ? r.result.declarerChange : r.result.opponentChange));
  Map<String,dynamic> toJson() => {'rules': rules.toJson(), 'teamA': teamA, 'teamB': teamB, 'target': target, 'rounds': rounds.map((e)=>e.toJson()).toList()};
  static GameState? fromJson(Map<String,dynamic> j) {
    try {
      final type = (j['rules']['type'] == 'shelem200') ? GameType.shelem200 : GameType.shelem165;
      final rules = RuleSet.fromType(type);
      final state = GameState(rules: rules, teamA: List<String>.from(j['teamA']), teamB: List<String>.from(j['teamB']), target: j['target']);
      for (final x in (j['rounds'] as List)) {
        final input = RoundInput(contract: x['contract'], declarerRaw: x['declarerRaw'], opponentRaw: x['opponentRaw'], declarer: x['declarer']);
        state.rounds.add(GameRound(x['id'], input, ScoringEngine.calculate(rules, input)));
      }
      return state;
    } catch (_) { return null; }
  }
}

class GameStore extends ChangeNotifier {
  GameState? game;
  bool loading = true;
  Future<void> load() async { final p=await SharedPreferences.getInstance(); final s=p.getString('game'); if(s!=null) game=GameState.fromJson(jsonDecode(s)); loading=false; notifyListeners(); }
  Future<void> save() async { if(game==null)return; final p=await SharedPreferences.getInstance(); await p.setString('game', jsonEncode(game!.toJson())); notifyListeners(); }
  Future<void> newGame(GameState g) async { game=g; await save(); }
  Future<void> addRound(RoundInput i) async { final g=game!; g.rounds.add(GameRound(DateTime.now().microsecondsSinceEpoch.toString(), i, ScoringEngine.calculate(g.rules,i))); await save(); }
  Future<void> undo() async { if(game!.rounds.isNotEmpty){game!.rounds.removeLast(); await save();} }
  Future<void> deleteRound(int index) async { game!.rounds.removeAt(index); await save(); }
}

class ShelemYarApp extends StatefulWidget { const ShelemYarApp({super.key}); @override State<ShelemYarApp> createState()=>_ShelemYarAppState(); }
class _ShelemYarAppState extends State<ShelemYarApp> {
  final store=GameStore(); @override void initState(){super.initState();store.load();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation: store,builder: (_,__)=>MaterialApp(debugShowCheckedModeBanner:false, title:'شلم‌یار', theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.deepPurple,fontFamily:'sans-serif'), darkTheme:ThemeData.dark(useMaterial3:true), home:Directionality(textDirection:TextDirection.rtl,child:store.loading?const Scaffold(body:Center(child:CircularProgressIndicator())):store.game==null?SetupPage(store:store):ScorePage(store:store))));
}

class SetupPage extends StatefulWidget { final GameStore store; const SetupPage({super.key,required this.store}); @override State<SetupPage> createState()=>_SetupPageState(); }
class _SetupPageState extends State<SetupPage> {
  GameType? type; final players=List.generate(4,(_)=>TextEditingController()); final target=TextEditingController(text:'1165');
  @override void dispose(){for(final c in players)c.dispose();target.dispose();super.dispose();}
  Future<void> start() async { if(type==null||players.any((c)=>c.text.trim().isEmpty)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ابتدا نوع بازی و نام هر چهار بازیکن را وارد کنید.')));return;} final g=GameState(rules:RuleSet.fromType(type!),teamA:[players[0].text,players[2].text],teamB:[players[1].text,players[3].text],target:int.tryParse(target.text)??1165); await widget.store.newGame(g); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('شلم‌یار | بازی جدید')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('کدام نوع شلم را بازی می‌کنید؟',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:16),RadioListTile(value:GameType.shelem165,groupValue:type,onChanged:(v)=>setState(()=>type=v),title:const Text('شلم ۱۶۵ امتیازی'),subtitle:const Text('مجموع هر دور ۱۶۵ امتیاز')),RadioListTile(value:GameType.shelem200,groupValue:type,onChanged:(v)=>setState(()=>type=v),title:const Text('شلم ۲۰۰ امتیازی با جوکر'),subtitle:const Text('مجموع هر دور ۲۰۰ امتیاز')),const Divider(height:32),const Text('نام بازیکنان',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...List.generate(4,(i)=>Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:players[i],decoration:InputDecoration(border:const OutlineInputBorder(),labelText:'بازیکن ${i+1}')))),const SizedBox(height:12),TextField(controller:target,keyboardType:TextInputType.number,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'امتیاز هدف')),const SizedBox(height:16),FilledButton(onPressed:start,child:const Padding(padding:EdgeInsets.all(12),child:Text('شروع بازی',style:TextStyle(fontSize:18))))]));
}

class ScorePage extends StatelessWidget { final GameStore store; const ScorePage({super.key,required this.store});
  Future<void> add(BuildContext context) async { final g=store.game!; final result=await showModalBottomSheet<RoundInput>(context:context,isScrollControlled:true,builder:(_)=>RoundSheet(rules:g.rules)); if(result!=null){try{await store.addRound(result);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('دست با موفقیت ثبت شد.')));}catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Invalid argument(s): ',''))));}} }
  @override Widget build(BuildContext context){final g=store.game!; final wonA=g.scoreA>=g.target,wonB=g.scoreB>=g.target; return Scaffold(appBar:AppBar(title:Text(g.rules.title),actions:[IconButton(onPressed:g.rounds.isEmpty?null:store.undo,icon:const Icon(Icons.undo),tooltip:'بازگردانی آخرین دست')]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>add(context),label:const Text('ثبت دست'),icon:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[Text(g.rules.title,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:10),Row(children:[Expanded(child:TeamScore(name:g.teamA.join(' و '),score:g.scoreA,won:wonA)),const Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Text('در برابر')),Expanded(child:TeamScore(name:g.teamB.join(' و '),score:g.scoreB,won:wonB))]),const SizedBox(height:8),Text('هدف بازی: ${g.target} | مجموع هر دست: ${g.rules.totalPoints}')]))),const SizedBox(height:12),const Text('تاریخچه دست‌ها',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...List.generate(g.rounds.length,(i){final r=g.rounds[g.rounds.length-1-i];final d=r.input.declarer=='A'?g.teamA.join(' و '):g.teamB.join(' و ');return Card(child:ListTile(title:Text('دست ${g.rounds.length-i} | حاکم: $d'),subtitle:Text('تعهد ${r.input.contract} | خام: ${r.input.declarerRaw} - ${r.input.opponentRaw}\n${r.result.message}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>store.deleteRound(g.rounds.length-1-i))));}),if(g.rounds.isEmpty)const Padding(padding:EdgeInsets.all(32),child:Center(child:Text('هنوز دستی ثبت نشده است.')))]));}
}
class TeamScore extends StatelessWidget{final String name;final int score;final bool won;const TeamScore({super.key,required this.name,required this.score,required this.won});@override Widget build(BuildContext c)=>Column(children:[Text(name,textAlign:TextAlign.center),const SizedBox(height:6),Text('$score',style:TextStyle(fontSize:36,fontWeight:FontWeight.bold,color:won?Colors.green:null)),if(won)const Text('🏆 برنده')]);}

class RoundSheet extends StatefulWidget{final RuleSet rules;const RoundSheet({super.key,required this.rules});@override State<RoundSheet> createState()=>_RoundSheetState();}
class _RoundSheetState extends State<RoundSheet>{String declarer='A';int? contract;final raw=TextEditingController();@override void dispose(){raw.dispose();super.dispose();}
void preview(){final d=int.tryParse(raw.text);if(contract==null||d==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعهد و امتیاز تیم حاکم را وارد کنید.')));return;}final input=RoundInput(contract:contract!,declarerRaw:d,opponentRaw:widget.rules.totalPoints-d,declarer:declarer);try{final r=ScoringEngine.calculate(widget.rules,input);showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('نتیجه این دست'),content:Text('امتیاز خام حاکم: ${r.declarerRaw}\nامتیاز خام حریف: ${r.opponentRaw}\n${r.message}\nتغییر امتیاز: ${r.declarerChange} / ${r.opponentChange}'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('ویرایش')),FilledButton(onPressed:(){Navigator.pop(c);Navigator.pop(context,input);},child:const Text('تأیید و ثبت'))]));}catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Invalid argument(s): ',''))));}}
@override Widget build(BuildContext c)=>Padding(padding:EdgeInsets.only(left:20,right:20,top:20,bottom:20+MediaQuery.of(c).viewInsets.bottom),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('ثبت دست | ${widget.rules.title}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),DropdownButtonFormField(value:declarer,items:const [DropdownMenuItem(value:'A',child:Text('تیم اول حاکم است')),DropdownMenuItem(value:'B',child:Text('تیم دوم حاکم است'))],onChanged:(v)=>setState(()=>declarer=v!),decoration:const InputDecoration(labelText:'حاکم')),DropdownButtonFormField<int>(value:contract,items:widget.rules.validContracts.map((x)=>DropdownMenuItem(value:x,child:Text('$x'))).toList(),onChanged:(v)=>setState(()=>contract=v),decoration:const InputDecoration(labelText:'تعهد')),TextField(controller:raw,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'امتیاز خام تیم حاکم (از ${widget.rules.totalPoints})')),const SizedBox(height:16),FilledButton(onPressed:preview,child:const Text('محاسبه و مشاهده نتیجه'))])));}
