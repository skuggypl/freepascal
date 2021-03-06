{$inline on}

procedure test(l1, l2: longint; var l3: longint);

var
  a1: cardinal;
  d1, d2: double;
  a2: cardinal;

  procedure nested; inline;
    begin
      l1:=1;
      l2:=2;
      l3:=5;
      d1:=3.0;
      d2:=4.0;
    end;

begin
  a1:=$deadbeef;
  a2:=$cafe0000;
  nested;
  if a1<>$deadbeef then
    halt(1);
  if a2<>$cafe0000 then
    halt(2);
  if l1<>1 then
    halt(3);
  if l2<>2 then
    halt(4);
  if d1<>3.0 then
    halt(5);
  if d2<>4.0 then
    halt(6);
  if l3<>5 then
    halt(7);
end;

var
  a3: longint;
begin
  a3:=1;
  test(5,6,a3);
end.
