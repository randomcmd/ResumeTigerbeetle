
---A representation of a 3D Vector
---@class Vector3D
---@field x number
---@field y number
---@field z number
---@field length number READ-ONLY
---@overload fun(x: number, y: number, z: number): Vector3D
Vector3D = class("Vector3D").extends() or Vector3D
function Vector3D:init(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    self.length = math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
end

--- Performed automatically by all operations
--- this recalculates the subsequent properties
function Vector3D:_recalculate()
    self.length = math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
end


function Vector3D:rotateByOnYAxis(rot)
    self.x = 0 * math.cos(rot) + 1 * math.sin(rot)
    self.z = 0 * math.sin(rot) + 1 * math.cos(rot)
end

function Vector3D.rotateByOnYAxis_(vector, rot)
    vector.x = 0 * math.cos(rot) + 1 * math.sin(rot)
    vector.z = 0 * math.sin(rot) + 1 * math.cos(rot)
    return vector
end

---Adds this vector to another vector (puts in to the same)
---returns this vector modified
---@param other any
---@returns Vector3D
function Vector3D:add(other)
    self.x += other.x
    self.y += other.y
    self.z += other.z
    self:_recalculate()
    return self
end

---Adds a vector with another vector
---@param v1 Vector3D
---@param v2 Vector3D
function Vector3D.add_(v1, v2)
    return Vector3D(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
end

---Multiplies this Vector3D by a number
---@param number number
---@return Vector3D
function Vector3D:multiply(number)
    self.x *= number
    self.y *= number
    self.z *= number
    return self
end

---Multiplies a Vector3D by a number
---@param vector Vector3D
---@param number number
function Vector3D.multiply_(vector, number)
    return Vector3D(vector.x * number, vector.y * number, vector.z * number)
end

--- Performs a dot product on the current vector
--- returns this vector modified
--- @param other Vector3D
function Vector3D:dot_product(other)
    self.x *= other.x
    self.y *= other.y
    self.z *= other.z
    self:_recalculate()
    return self
end

--- Performs a dot product on two Vectors
--- returns a new Vector3
--- @param v1 Vector3D
--- @param v2 Vector3D
--- @returns Vector3D
function Vector3D.dot_product_(v1, v2)
    local v = Vector3D(v1.x, v1.y, v1.z)
    v.x *= v2.x
    v.y *= v2.y
    v.z *= v2.z
    return v
end

---Normalizes this Vector3D
---https://en.wikipedia.org/wiki/Unit_vector
---@return Vector3D
function Vector3D:normalize()
    self.x /= self.length
    self.y /= self.length
    self.z /= self.length
    self:_recalculate()
    return self
end

---Normalizes this Vector3D
---https://en.wikipedia.org/wiki/Unit_vector
---@param vector Vector3D
---@return Vector3D
function Vector3D:normalize(vector)
    vector.x /= vector.length
    vector.y /= vector.length
    vector.z /= vector.length
    vector:_recalculate()
    return vector
end

---Create a Vector3D result of their dot product between this and another Vector3D
---@param other Vector3D
function Vector3D:cross_product(other)
    return Vector3D(self.y * other.z - self.z * other.y,
    self.z * other.x - self.x * other.z,
    self.x * other.y - self.y * other.x)
end

---Create a Vector3D result of their dot product between 2 Vector3D
---@param v1 Vector3D
---@param v2 Vector3D
function Vector3D.cross_product_(v1, v2)
    return Vector3D(v1.y * v2.z - v1.z * v2.y,
    v1.z * v2.x - v1.x * v2.z,
    v1.x * v2.y - v1.y * v2.x)
end