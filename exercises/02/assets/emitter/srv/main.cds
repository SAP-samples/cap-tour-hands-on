namespace codejam.emitter;

@rest
service EmitterService {
  action greet(greeting: String) returns String;

  event Greeting.Received {
    info : String;
  }
}
