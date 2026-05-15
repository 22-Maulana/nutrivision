<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ActivationMail extends Mailable
{
    use Queueable, SerializesModels;

    public $otpCode;

    /**
     * Create a new message instance.
     */
    public function __construct($otpCode)
    {
        $this->otpCode = $otpCode;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'NutriVision - Kode Aktivasi Akun Anda',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            htmlString: '
            <div style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
                <h2 style="color: #4CAF50;">Selamat Datang di NutriVision!</h2>
                <p>Terima kasih telah mendaftar. Untuk menyelesaikan proses registrasi dan mengaktifkan akun Anda, silakan gunakan kode OTP berikut:</p>
                <h1 style="background: #f4f4f4; padding: 15px; border-radius: 10px; display: inline-block; letter-spacing: 5px;">' . $this->otpCode . '</h1>
                <p>Kode ini akan meminta Anda memasukkannya di dalam aplikasi.</p>
                <p style="color: #888; font-size: 12px; margin-top: 30px;">Tim NutriVision &copy; ' . date('Y') . '</p>
            </div>
            '
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
