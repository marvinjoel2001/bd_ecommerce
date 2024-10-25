DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce;
USE ecommerce;


CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    fecha_registro DATE NOT NULL,
    direccion TEXT NOT NULL
);

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    categoria VARCHAR(50) NOT NULL
);



CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalles_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);


INSERT INTO clientes VALUES
(1, 'Juan', 'Pérez', 'juanga@gmail.com', '76543210', '2023-01-15', 'Calle 1 #123'),
(2, 'María', 'López', 'mariaLau@gmail.com', '76543211', '2023-02-01', 'Av. Principal #456'),
(3, 'Carlos', 'García', 'carlos4@gmail.com', '76543212', '2023-03-10', 'Barrio Central #789'),
(4, 'Ana', 'Martínez', 'ana55@gmail.com', '76543213', '2023-04-20', 'Zona Norte #321'),
(5, 'Luis', 'Rodríguez', 'luis2002@gmail.com', '76543214', '2023-05-05', 'Calle 2 #654');

INSERT INTO productos VALUES
(1, 'Telefono Samsung A53', 'Samsung Galaxy A53 128GB', 2499.99, 10, 'Celulares'),
(2, 'Laptop HP', 'HP Pavilion 15.6" Core i5', 5999.99, 5, 'Computadoras'),
(3, 'Audifonos Sony', 'Sony WH-1000XM4', 1499.99, 15, 'Accesorios'),
(4, 'Smart TV LG', 'LG 55" 4K Smart TV', 4999.99, 8, 'Televisores'),
(5, 'iPad', 'iPad 10na Gen 64GB', 3499.99, 12, 'Tablets');

INSERT INTO pedidos VALUES
(1, 1, '2024-10-01 10:30:00', 'Entregado', 2499.99),
(2, 2, '2024-10-05 15:45:00', 'En proceso', 5999.99),
(3, 1, '2024-10-10 09:15:00', 'Pendiente', 1499.99),
(4, 3, '2024-10-15 14:20:00', 'Entregado', 4999.99),
(5, 4, '2024-10-20 11:30:00', 'En proceso', 3499.99);



INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 1, 2499.99, 2499.99),-- Pedido 1: Juan compró un Smartphone
(2, 2, 1, 5999.99, 5999.99),-- Pedido 2: María compró una Laptop
(3, 3, 1, 1499.99, 1499.99),-- Pedido 3: Juan compró audífonos
(4, 4, 1, 4999.99, 4999.99),-- Pedido 4: Carlos compró un Smart TV
(5, 5, 1, 3499.99, 3499.99), -- Pedido 5: Ana compró un iPad
(1, 3, 2, 1499.99, 2999.98),  -- Juan tambien compro 2 audífonos
(2, 4, 1, 4999.99, 4999.99),  -- María también compro un televisor
(3, 5, 1, 3499.99, 3499.99),  -- Juan también compro un iPad
(4, 1, 2, 2499.99, 4999.98),  -- Carlos compra 2 smartphones
(5, 2, 1, 5999.99, 5999.99);  -- Ana también compra una laptop


CREATE INDEX idx_fecha_pedido ON pedidos(fecha_pedido);
CREATE INDEX idx_total ON pedidos(total);
CREATE INDEX idx_producto_cantidad ON detalles_pedido(id_producto, cantidad);







-- 1. Clientes con más pedidos en últimos 6 meses
SELECT 
    c.nombre,
    c.apellido,
    c.email,
    COUNT(*) as numero_pedidos,
    SUM(p.total) as monto_total_compras
FROM clientes c
INNER JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.fecha_pedido >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY c.id_cliente, c.nombre, c.apellido, c.email
ORDER BY numero_pedidos DESC, monto_total_compras DESC
LIMIT 10;

-- 2. Producto más vendido del último mes
SELECT 
    p.nombre as producto,
    p.categoria,
    SUM(dp.cantidad) as unidades_vendidas,
    SUM(dp.subtotal) as ingreso_total
FROM productos p
INNER JOIN detalles_pedido dp ON p.id_producto = dp.id_producto
INNER JOIN pedidos ped ON dp.id_pedido = ped.id_pedido
WHERE ped.fecha_pedido >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    AND ped.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre, p.categoria
ORDER BY unidades_vendidas DESC
LIMIT 1;


-- 3. Clientes sin pedidos en el último año
SELECT 
    c.nombre,
    c.apellido,
    c.email,
    c.telefono,
    c.fecha_registro,
    (SELECT MAX(fecha_pedido) 
     FROM pedidos 
     WHERE id_cliente = c.id_cliente) as ultima_compra
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente 
    AND p.fecha_pedido >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
WHERE p.id_pedido IS NULL
ORDER BY ultima_compra DESC;



-- 4. Pedidos que superan 5000 Bs
SELECT 
    p.id_pedido,
    c.nombre as cliente,
    p.fecha_pedido,
    p.estado,
    p.total,
    COUNT(dp.id_detalle) as numero_items,
    GROUP_CONCAT(pr.nombre SEPARATOR ', ') as productos
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
INNER JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
INNER JOIN productos pr ON dp.id_producto = pr.id_producto
WHERE p.total > 5000
GROUP BY p.id_pedido, c.nombre, p.fecha_pedido, p.estado, p.total
ORDER BY p.total DESC;




