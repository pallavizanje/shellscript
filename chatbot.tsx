import React, { useState } from 'react';

interface Message {
  sender: 'user' | 'bot';
  text: string;
}

const ChatBot: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');

  const handleSend = () => {
    if (!input.trim()) return;

    const userMessage: Message = { sender: 'user', text: input };
    const botMessage: Message = { sender: 'bot', text: `Echo: ${input}` };

    setMessages(prev => [...prev, userMessage, botMessage]);
    setInput('');
  };

  return (
    <div className="flex flex-col max-w-md mx-auto h-screen p-4 bg-gray-100 shadow-lg rounded-lg">
      <h2 className="text-xl font-semibold text-center mb-4">ChatBot</h2>

      <div className="flex-1 overflow-y-auto space-y-2 p-2 bg-white rounded-md shadow-inner">
        {messages.map((msg, idx) => (
          <div
            key={idx}
            className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`px-4 py-2 rounded-lg text-white ${
                msg.sender === 'user' ? 'bg-blue-500' : 'bg-gray-500'
              }`}
            >
              {msg.text}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-4 flex">
        <input
          type="text"
          className="flex-1 px-4 py-2 border rounded-l-md focus:outline-none"
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
          placeholder="Type a message..."
        />
        <button
          className="bg-blue-600 text-white px-4 rounded-r-md hover:bg-blue-700"
          onClick={handleSend}
        >
          Send
        </button>
      </div>
    </div>
  );
};

export default ChatBot;
