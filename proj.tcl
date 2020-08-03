if {$argc == 5} {
	set cenario [lindex $argv 0]
	set protocolo [lindex $argv 1]
	set janela [lindex $argv 2]
	set falha [lindex $argv 3]
	set velocidade [lindex $argv 4]


} elseif {$argc == 4} {
	set cenario [lindex $argv 0]
	set protocolo [lindex $argv 1]
	set janela 20
	set falha [lindex $argv 2]
	set velocidade [lindex $argv 3]
} else {
    puts "\nCenario(1 ou 2);Protocolo(TCP ou UDP);Janela(caso seja TCP int);Falha(S/N);Velocidade;\n"
    exit 1
}

set ns [new Simulator]
set nf [open out.nam w]

$ns namtrace-all $nf

set nt [open out.tr w]
$ns trace-all $nt

$ns color 0 Red
$ns color 1 Blue
$ns color 2 Green



proc fim {} {
	global ns nf
	$ns flush-trace
	close $nf
	exec nam out.nam
	exit 0
}

set PCA [$ns node]
set PCB [$ns node]
set PCC [$ns node]
set R3 [$ns node]
set R4 [$ns node]
set PCD [$ns node]
set R6 [$ns node]
set PCE [$ns node]

#cores formas
$PCA color blue
$PCA shape hexagon
$PCB color red
$PCB shape square
$PCD color green
$PCD shape square
$PCE color blue
$PCE shape hexagon
$PCA label "PC A"
$PCB label "PC B"
$PCC label "PC C"
$R3 label "R3"
$R4 label "R4"
$PCD label "PC D"
$R6 label "R6"
$PCE label "PC E"


$ns duplex-link $PCA $PCB $velocidade+Mb 10ms DropTail
$ns duplex-link $PCB $PCC 10Mb 10ms DropTail
$ns duplex-link $PCC $R3 10Mb 10ms DropTail
$ns duplex-link $R3 $R6 10Mb 10ms DropTail
$ns duplex-link $R6 $PCD 10Mb 10ms DropTail
$ns duplex-link $PCD $R4 10Mb 10ms DropTail
$ns simplex-link $R4 $PCB 10Mb 5ms DropTail
$ns duplex-link $PCC $PCD 10Mb 10ms DropTail
$ns duplex-link $PCD $PCE 10Mb 10ms DropTail

$ns duplex-link-op $PCA $PCB queuePos 0.5
$ns duplex-link-op $PCB $PCC queuePos 0.5
$ns duplex-link-op $PCC $R3 queuePos 0.5
$ns duplex-link-op $R3 $R6 queuePos 0.5
$ns duplex-link-op $R6 $PCD queuePos 0.5
$ns duplex-link-op $PCD $R4 queuePos 0.5
$ns simplex-link-op $R4 $PCB queuePos 0.5
$ns duplex-link-op $PCC $PCD queuePos 0.5
$ns duplex-link-op $PCD $PCE queuePos 0.5

$ns duplex-link-op $PCA $PCB orient left-right
$ns duplex-link-op $PCB $PCC orient left-right
$ns duplex-link-op $PCC $R3 orient left-right
$ns duplex-link-op $R3 $R6 orient down
$ns duplex-link-op $R6 $PCD orient left
$ns duplex-link-op $PCD $R4 orient left
$ns simplex-link-op $R4 $PCB orient up
$ns duplex-link-op $PCC $PCD orient down
$ns duplex-link-op $PCD $PCE orient down

$ns queue-limit $PCA $PCB 2098

########################################protocolo#################################################

if {$protocolo == "TCP"} {

	# Cria o TCP
	set tcp [$ns create-connection TCP $PCA TCPSink $PCE 1]
	$tcp set window_ $janela
	$tcp set class_ 1

	#Cria cbr0 para enviar os 2MB
	#2MB = 2 * 1024 * 1024 bytes = 2097152
	set cbr0 [new Application/Traffic/CBR]
	$cbr0 set packetSize_ 2097152
	$cbr0 set maxpkts_ 1
	$cbr0 attach-agent $tcp

} elseif {$protocolo == "UDP"} {

	#Cria um agente UDP e liga-o ao nó servidor1
	set udp0 [new Agent/UDP]
	$ns attach-agent $PCA $udp0
	$udp0 set class_ 1

	#Cria uma fonte de tráfego CBR0 e liga-a ao udp0
	set cbr0 [new Application/Traffic/CBR]
	$cbr0 set packetSize_ 2097152
	$cbr0 set maxpkts_ 1

	$cbr0 attach-agent $udp0

	#Cria um agente Null e liga-o ao nó receptor1
	set null0 [new Agent/Null]
	$ns attach-agent $PCE $null0

	$ns connect $udp0 $null0

} else {
	exit 1
}

###########################################cenarios###############################################

if {$cenario==1} {
	#Nada muda
	
} elseif {$cenario == 2} {
	#1stream
	set udp1 [new Agent/UDP]
	$udp1 set class_ 0
	$ns attach-agent $PCB $udp1
	set cbr1 [new Application/Traffic/CBR]
	$cbr1 attach-agent $udp1
	$cbr1 set rate_ 6000000

	set null1 [new Agent/Null]
	$ns attach-agent $PCD $null1 
	$ns connect $udp1 $null1
	$ns at 0.5 "$cbr1 start"

	#2stream
	set udp2 [new Agent/UDP]
	$udp2 set class_ 2
	$ns attach-agent $PCD $udp2
	set cbr2 [new Application/Traffic/CBR]
	$cbr2 attach-agent $udp2
	$cbr2 set rate_ 5000000

	set null2 [new Agent/Null]
	$ns attach-agent $PCC $null2 
	$ns connect $udp2 $null2
	$ns at 0.5 "$cbr2 start"

	
} else {
	exit 1
}

$ns at 0.5 "$cbr0 start"

###############################################falha############################################

if {$falha == "S"} {
	$ns rtproto LS
	#Falha de ligaçao
	$ns rtmodel-at 0.75 down $PCC $PCD 
	$ns rtmodel-at 0.9 up $PCC $PCD
	
} elseif {$falha == "N"} {
	#nada acontece
	
} else {
	exit 1
}



$ns at 10.0 "fim"

$ns run
