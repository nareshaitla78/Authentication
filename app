const express = require('express')
const path = require('path')
const {open} = require('sqlite')
const sqlite3 = require('sqlite3')
const bcrypt = require('bcrypt')
const app = express()
app.use(express.json())
const dbPath = path.join(__dirname, 'userData.db')
let db = null
const initializeDbAndServer = async () => {
  try {
    db = await open({
      filename: dbPath,
      driver: sqlite3.Database,
    })
    app.listen(3001, () => {
      console.log('Server Is Running http://localhost:3000/')
    })
  } catch (e) {
    console.log(`Error B: ${e.message}`)
    process.exit(1)
  }
}

initializeDbAndServer()
const validatePassword = password => {
  return password.length > 4
}

app.post('/register', async (request, response) => {
  const {username, name, password, gender, location} = request.body
  const hashedPassword = await bcrypt.hash(password, 10)
  const selectUserQuery = `SELECT * FROM user WHERE username = '${username}';`

  const dbUser = await db.run(selectUserQuery)

  if (dbUser == undefined) {
    const postSalQuery = `
        INSERT INTO 
        user (username, name, password, gender, location)
        VALUES (
            '${username}',
            '${name}',
            '${hashedPassword}',
            '${gender}',
            '${location}'
        );`

    if (validatePassword(password)) {
      await db.run(postSalQuery)
      response.send('User created successfully')
    } else {
      response.status(400)
      response.send('Password is too short')
    }
  } else {
    response.send(400)
    response.send('User already exists')
  }
})
app.post('/login', async (request, response) => {
  const {username, password} = request.body
  const selectUserQuery = `SELECT * FROM user WHERE username = '${username}';`

  const dbUser = await db.run(selectUserQuery)
  if (dbUser == undefined) {
    response.status(400)
    response.send('Invalid user')
  } else {
    const isPasswordMacthed = await bcrypt.campare(password, dbUser.password)
    if (isPasswordMacthed === true) {
      response.send('Login success!')
    } else {
      response.status(400)
      response.send('Invalid password')
    }
  }
})

app.put('/change-password', async (request, response) => {
  const {username, oldPassword, newPassword} = request.body
  const selectUserQuery = `SELECT * FROM user WHERE username = '${username}';`

  const dbUser = await db.run(selectUserQuery)
  if (dbUser == undefined) {
    response.status(400)
    response.send('Invalid user')
  } else {
    const isPasswordMacthed = await bcrypt.compare(oldPassword, dbUser.password)
    if (isPasswordMacthed === true) {
      if (validatePassword(newPassword)) {
        const hashedPassword = await bcrypt.hash(newPassword, 10)
        const sqlQuery = `
        UPDATE
         user
        SET 
        password='${hashedPassword}'
        WHERE username='${username}';`
        const user = await db.run(sqlQuery)
        response.send('Password updated')
      } else {
        response.status(400)
        response.send('Password is too short')
      }
    } else {
      response.status(400)
      response.send('Invalid current password')
    }
  }
})
module.exports = app
