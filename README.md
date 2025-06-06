// SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.0;


contract Subasta {
  address public admin; 
  address public mejorOferente; 
  uint256 public mejorOferta;
  // se guardara el tiempo exacto en que termina la subasta 
  uint256 private finSubasta; 
  bool private activa;  
  //creamos una tabla que almacene el dinero que debe devolver a cada oferente que no gano 
  mapping(address => uint) public ofertas;
  // creamos una lista de todas las personas que ofertaron sin el ganador .
  address[] public oferentes;

//--------eventos--------
event NuevaOferta(address oferente, uint monto); //quien oferta
event SubastaFinalizada(address ganador, uint monto); //quien gano 
event Reembolso(address usuario, uint monto);//quien recibe reembolso

//-------constructor-----

constructor(uint duracionMinutos) {
  //muestra quien es el administrador a cargo
    admin = msg.sender;
  //determina cuando termina la subasta 
    finSubasta = block.timestamp + duracionMinutos * 1 minutes;
  //muestra la subasta activa 
    activa = true;
}

//mientras la subasta este abierta  y no se acabe el tiempo 

modifier soloMientrasActiva() {
    require(activa, "La subasta ya termino");
    require(block.timestamp < finSubasta, "Tiempo agotado");
    _;
}

function ofertar() external payable soloMientrasActiva {
  require(msg.value > mejorOferta + (mejorOferta * 5) / 100, "La oferta debe ser al menos 5% mayor");

//si hay un mejor oferente , se le guarda su dinero para reembolso
  if (mejorOferente != address(0)) {
    ofertas[mejorOferente] += mejorOferta;
  }
// si es la primera vez que oferta se le agrega a la lista de oferentes
if (ofertas[msg.sender] == 0 && msg.sender != mejorOferente && msg.sender != admin) {
    oferentes.push(msg.sender);
}
//se actualiza los datos del nuevo ganador y su oferta
mejorOferente = msg.sender;
mejorOferta = msg.value;

// si  se realiza una oferta dentro del tiempo, se extiende otros 10min
if (finSubasta - block.timestamp < 10 minutes) {
    finSubasta += 10 minutes;
    emit NuevaOferta(msg.sender, msg.value); // notificamos la nueva oferta 
}
}
function finalizarSubasta() external {
  require(msg.sender == admin, "Solo el admin puede finalizar");
  require(activa, "La subasta ya esta finalizada"); //verificara que la subasta siga activa
  require(block.timestamp >= finSubasta, "La subasta no ha terminado");// verificara si el tiempo termino
  // una vez terminado el tiempo , se marcara como cerrada dando el dinero al administ y nos mostrara en pantalla quien gano
  activa = false;  
  payable(admin).transfer(mejorOferta);
  emit SubastaFinalizada(mejorOferente, mejorOferta);

}

function reclamarReembolso() external {
  // verificamos que no sea el ganador quien pida reembolso
  require(msg.sender != mejorOferente, "Usted gano , no recibe reembolso"); 
  //verificamos si tiene reembolsos
  uint256 monto = ofertas[msg.sender]; 
  require(monto > 0, "No hay reembolsos pendientes");

  //Hacemos el descuento del 2%  de comision 
  uint256 descuento = (monto * 2) / 100;
  uint256 devolver = monto - descuento;
  //Borramos su saldo pendiente y se le transfiere el dinero  
  ofertas[msg.sender] = 0;
  payable(msg.sender).transfer(devolver);
  emit Reembolso(msg.sender, devolver);

}

function obtenerOferentes() external view returns (address[] memory, uint[] memory) {
  //devolveremos la lista de oferentes y sus montos para sus posibles reembolsos 
    uint256[] memory montos = new uint256[](oferentes.length);
    for (uint256 i = 0; i < oferentes.length; i++) {
        montos[i] = ofertas[oferentes[i]];
    }
    return (oferentes, montos);
    }

function tiempoRestante() external view returns (uint) {
  //calculamos el tiempo restante y si acaba mostra un 0 
    return block.timestamp >= finSubasta ? 0 : finSubasta - block.timestamp;
}


function estadoSubasta() external view returns (string memory) {
    return activa ? "La subasta esta abierta" : "La subasta cerro";
}

}
