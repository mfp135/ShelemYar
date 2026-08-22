import 'package:flutter_test/flutter_test.dart';
import 'package:shelemyar/main.dart';
void main(){
 group('Shelem 165',(){
  final r=RuleSet.fromType(GameType.shelem165);
  test('total 165 success',(){final x=ScoringEngine.calculate(r,const RoundInput(contract:120,declarerRaw:120,opponentRaw:45,declarer:'A'));expect(x.status,ContractStatus.success);expect(x.declarerChange,120);});
  test('invalid total rejected',(){expect(()=>ScoringEngine.calculate(r,const RoundInput(contract:120,declarerRaw:100,opponentRaw:40,declarer:'A')),throwsArgumentError);});
  test('failure',(){final x=ScoringEngine.calculate(r,const RoundInput(contract:120,declarerRaw:100,opponentRaw:65,declarer:'A'));expect(x.status,ContractStatus.failure);expect(x.declarerChange,-120);});
 });
 group('Shelem 200',(){final r=RuleSet.fromType(GameType.shelem200);test('total 200 success',(){final x=ScoringEngine.calculate(r,const RoundInput(contract:150,declarerRaw:150,opponentRaw:50,declarer:'A'));expect(x.status,ContractStatus.success);});test('165 total rejected in 200',(){expect(()=>ScoringEngine.calculate(r,const RoundInput(contract:120,declarerRaw:120,opponentRaw:45,declarer:'A')),throwsArgumentError);});});
}
