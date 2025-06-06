// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract SubastaSimple {
    address private  admin;
    address public mejorOferente;
    uint256 public mejorOferta;
    uint256 private finSubasta;     
    bool private activa;         

    mapping(address => uint) public ofertas;
    address[] public oferentes;

    event NuevaOferta(address oferente, uint monto);
    event SubastaFinalizada(address ganador, uint monto);
    event Reembolso(address usuario, uint monto);

    constructor(uint duracionMinutos) {
        admin = msg.sender;
        finSubasta = block.timestamp + duracionMinutos * 1 minutes;
        activa = true;
    }

    modifier soloMientrasActiva() {
        require(activa, "La subasta ya termino");
        require(block.timestamp < finSubasta, "El tiempo termino");
        _;
    }

    function ofertar() external payable soloMientrasActiva {
        require(msg.value > mejorOferta + (mejorOferta * 5) / 100, "La oferta debe ser al menos 5% mayor");

        if (mejorOferente != address(0)) {
            ofertas[mejorOferente] += mejorOferta;
        }

        if (ofertas[msg.sender] == 0 && msg.sender != mejorOferente && msg.sender != admin) {
            oferentes.push(msg.sender);
        }

        mejorOferente = msg.sender;
        mejorOferta = msg.value;

        if (finSubasta - block.timestamp < 10 minutes) {
            finSubasta += 10 minutes;
        }

        emit NuevaOferta(msg.sender, msg.value);
    }

    function finalizarSubasta() external {
        require(msg.sender == admin, "Solo el administrador puede finalizar");
        require(activa, "La subasta ya esta finalizada");
        require(block.timestamp >= finSubasta, "La subasta no ha terminado");

        activa = false;
        payable(admin).transfer(mejorOferta);

        emit SubastaFinalizada(mejorOferente, mejorOferta);
    }

    function reclamarReembolso() external {
        require(msg.sender != mejorOferente, "Usted gano , no recibe reembolso");

        uint monto = ofertas[msg.sender];
        require(monto > 0, "Usted no tiene reembolsos pendientes");

        uint256 descuento = (monto * 2) / 100;
        uint256 devolver = monto - descuento;

        ofertas[msg.sender] = 0;
        payable(msg.sender).transfer(devolver);

        emit Reembolso(msg.sender, devolver);
    }

    function obtenerOferentes() external view returns (address[] memory, uint[] memory) {
        uint[] memory montos = new uint256[](oferentes.length);
        for (uint256 i = 0; i < oferentes.length; i++) {
            montos[i] = ofertas[oferentes[i]];
        }
        return (oferentes, montos);
    }

    function tiempoRestante() external view returns (uint) {
        return block.timestamp >= finSubasta ? 0 : finSubasta - block.timestamp;
    }

    function estadoSubasta() external view returns (string memory) {
        return activa ? "La subasta esta abierta" : "La subasta cerro";
    }
}